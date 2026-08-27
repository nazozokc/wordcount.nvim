local M = { windows = {} }
local positions = { top_left = true, top_right = true, bottom_left = true, bottom_right = true }

local function close(win) if win and vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end end

function M.close(winid) close(M.windows[winid]); M.windows[winid] = nil end

function M.show(winid, text, position)
  position = positions[position] and position or "top_right"
  if not vim.api.nvim_win_is_valid(winid) then return end
  M.close(winid)
  local width = math.max(1, vim.fn.strdisplaywidth(text)); local height = vim.api.nvim_win_get_height(winid); local win_width = vim.api.nvim_win_get_width(winid)
  local row = position:find("bottom") and math.max(0, height - 1) or 0
  local col = position:find("right") and math.max(0, win_width - width) or 0
  local buf = vim.api.nvim_create_buf(false, true); vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })
  local win = vim.api.nvim_open_win(buf, false, { relative = "win", win = winid, row = row, col = col, width = width, height = 1, style = "minimal", focusable = false })
  vim.api.nvim_set_option_value("winhl", "Normal:Normal", { win = win }); M.windows[winid] = win
end

return M
