local M = { windows = {} }
local positions = { top_left = true, top_right = true, bottom_left = true, bottom_right = true }
local position_order = { "top_left", "top_right", "bottom_left", "bottom_right" }

local function clamp(value, minimum, maximum)
  return math.max(minimum, math.min(value, maximum))
end

local function close(win)
  if win and vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
end

function M.close(winid)
  close(M.windows[winid])
  M.windows[winid] = nil
end

function M.close_all()
  for winid in pairs(M.windows) do M.close(winid) end
end

-- Drop counters whose target window no longer exists (closed split, closed tab, ...).
function M.prune()
  for winid in pairs(M.windows) do
    if not vim.api.nvim_win_is_valid(winid) then M.close(winid) end
  end
end

function M.remove_counter(counter)
  for winid, win in pairs(M.windows) do
    if win == counter then M.windows[winid] = nil end
  end
end

local function overlaps(a, b)
  return a.row < b.row + b.height and b.row < a.row + a.height
    and a.col < b.col + b.width and b.col < a.col + a.width
end

-- Only real windows of the current tab can act as obstacles. Floating windows
-- (including our own counters) have no meaningful position, and windows of
-- other tabpages would block positions they do not occupy on screen.
local function occupied_windows(exclude, exclude_counter)
  local occupied = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= exclude and win ~= exclude_counter and vim.api.nvim_win_is_valid(win) then
      if vim.api.nvim_win_get_config(win).relative == "" then
        local row, col = unpack(vim.api.nvim_win_get_position(win))
        occupied[#occupied + 1] = {
          row = row,
          col = col,
          width = vim.api.nvim_win_get_width(win),
          height = vim.api.nvim_win_get_height(win),
        }
      end
    end
  end
  return occupied
end

local function candidate(position, width, win_height, win_width)
  return {
    row = position:find("bottom") and math.max(0, win_height - 1) or 0,
    col = position:find("right") and math.max(0, win_width - width) or 0,
  }
end

function M.is_counter(win)
  for _, counter in pairs(M.windows) do
    if counter == win then return true end
  end
  return false
end

function M.show(winid, text, position)
  position = positions[position] and position or "top_right"
  if not vim.api.nvim_win_is_valid(winid) then return end

  local rows = vim.o.lines
  local columns = vim.o.columns
  -- The counter must never be narrower than its text, otherwise the number is
  -- cut off in narrow windows. Only clamp to the editor width.
  local width = clamp(vim.fn.strdisplaywidth(text), 1, math.max(1, columns))
  local win_height = vim.api.nvim_win_get_height(winid)
  local win_width = vim.api.nvim_win_get_width(winid)

  local counter = M.windows[winid]
  if counter and not vim.api.nvim_win_is_valid(counter) then
    M.windows[winid] = nil
    counter = nil
  end

  local occupied = occupied_windows(winid, counter)
  local alternatives = { position }
  for _, alternative in ipairs(position_order) do
    if alternative ~= position then alternatives[#alternatives + 1] = alternative end
  end
  local target_row, target_col = unpack(vim.api.nvim_win_get_position(winid))
  local initial = candidate(position, width, win_height, win_width)
  local selected = { row = target_row + initial.row, col = target_col + initial.col }
  for _, alternative in ipairs(alternatives) do
    local point = candidate(alternative, width, win_height, win_width)
    local rect = { row = target_row + point.row, col = target_col + point.col, width = width, height = 1 }
    local blocked = false
    for _, other in ipairs(occupied) do
      if overlaps(rect, other) then blocked = true; break end
    end
    if not blocked then
      selected = { row = rect.row, col = rect.col }
      break
    end
  end
  selected.row = clamp(selected.row, 0, math.max(0, rows - 1))
  selected.col = clamp(selected.col, 0, math.max(0, columns - width))

  if counter then
    local buf = vim.api.nvim_win_get_buf(counter)
    local current = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    if current ~= text then vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text }) end
    vim.api.nvim_win_set_config(counter, {
      relative = "editor",
      row = selected.row,
      col = selected.col,
      width = width,
      height = 1,
    })
    return
  end

  M.close(winid)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
  -- Editor-relative coordinates keep the counter aligned with its window even
  -- when Neovim has a tabline, a statusline, or other floating windows.
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = selected.row,
    col = selected.col,
    width = width,
    height = 1,
    style = "minimal",
    focusable = false,
  })
  vim.api.nvim_set_option_value("winhl", "Normal:Normal", { win = win })
  M.windows[winid] = win
end

return M
