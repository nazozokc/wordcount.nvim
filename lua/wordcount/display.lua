local M = { windows = {} }
local positions = { top_left = true, top_right = true, bottom_left = true, bottom_right = true }
local position_order = { "top_left", "top_right", "bottom_left", "bottom_right" }

local function close(win) if win and vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end end

function M.close(winid) close(M.windows[winid]); M.windows[winid] = nil end

local function overlaps(a, b)
  return a.row < b.row + b.height and b.row < a.row + a.height
    and a.col < b.col + b.width and b.col < a.col + a.width
end

local function occupied_windows(exclude)
  local occupied = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= exclude and vim.api.nvim_win_is_valid(win) then
      local row, col = unpack(vim.api.nvim_win_get_position(win))
      occupied[#occupied + 1] = {
        row = row,
        col = col,
        width = vim.api.nvim_win_get_width(win),
        height = vim.api.nvim_win_get_height(win),
      }
    end
  end
  return occupied
end

local function candidate(position, width, height, win_height, win_width)
  return {
    row = position:find("bottom") and math.max(0, win_height - height) or 0,
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
  M.close(winid)
  local width = math.min(math.max(1, vim.fn.strdisplaywidth(text)), vim.api.nvim_win_get_width(winid))
  local height = vim.api.nvim_win_get_height(winid); local win_width = vim.api.nvim_win_get_width(winid)
  local occupied = occupied_windows(winid)
  local selected = candidate(position, width, 1, height, win_width)
  local alternatives = { position }
  for _, alternative in ipairs(position_order) do
    if alternative ~= position then alternatives[#alternatives + 1] = alternative end
  end
  local target_row, target_col = unpack(vim.api.nvim_win_get_position(winid))
  for _, alternative in ipairs(alternatives) do
    local point = candidate(alternative, width, 1, height, win_width)
    local rect = { row = target_row + point.row, col = target_col + point.col, width = width, height = 1 }
    local blocked = false
    for _, other in ipairs(occupied) do
      if overlaps(rect, other) then blocked = true; break end
    end
    if not blocked then selected = point; break end
  end
  local buf = vim.api.nvim_create_buf(false, true); vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
  local win = vim.api.nvim_open_win(buf, false, { relative = "win", win = winid, row = selected.row, col = selected.col, width = width, height = 1, style = "minimal", focusable = false })
  vim.api.nvim_set_option_value("winhl", "Normal:Normal", { win = win }); M.windows[winid] = win
end

return M
