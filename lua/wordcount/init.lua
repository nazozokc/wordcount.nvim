local count = require("wordcount.count")
local display = require("wordcount.display")

local M = {
  config = {
    enabled = true,
    position = "top_right",
    debounce_ms = 100,
    format = "文字数: %d",
    markdown = { include_frontmatter = true },
  },
  enabled = false,
}

local pending = {}
local detail_win = nil

local function buffer_lines(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if vim.bo[buf].filetype == "markdown" and not M.config.markdown.include_frontmatter then
    return count.remove_frontmatter(lines)
  end
  return lines
end

local function is_target(win)
  if not vim.api.nvim_win_is_valid(win) or display.is_counter(win) then return false end
  -- Never attach counters to floating windows of other plugins.
  if vim.api.nvim_win_get_config(win).relative ~= "" then return false end
  return vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ""
end

local function refresh_window(winid)
  if not M.enabled or not vim.api.nvim_win_is_valid(winid) or display.is_counter(winid) then return end
  -- Floats are per tabpage, so windows of another tabpage must not be drawn here.
  if vim.api.nvim_win_get_tabpage(winid) ~= vim.api.nvim_get_current_tabpage() then return end
  if not is_target(winid) then
    display.close(winid)
    return
  end
  local stats = count.count(buffer_lines(vim.api.nvim_win_get_buf(winid)))
  display.show(winid, string.format(M.config.format, stats.total), M.config.position)
end

local function refresh_all()
  if not M.enabled then return end
  display.prune()
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    refresh_window(winid)
  end
end

local function refresh_buffer(buf)
  if not M.enabled then return end
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(winid) == buf then refresh_window(winid) end
  end
end

local function schedule(buf)
  if not M.enabled then return end
  pending[buf] = true
  if not M.timer then M.timer = (vim.uv or vim.loop).new_timer() end
  M.timer:stop()
  M.timer:start(M.config.debounce_ms, 0, vim.schedule_wrap(function()
    local buffers = pending
    pending = {}
    for changed in pairs(buffers) do refresh_buffer(changed) end
  end))
end

function M.refresh() refresh_window(vim.api.nvim_get_current_win()) end
function M.enable() M.enabled = true; refresh_all() end
function M.disable() M.enabled = false; pending = {}; display.close_all() end
function M.toggle() if M.enabled then M.disable() else M.enable() end end

function M.details()
  local stats = count.count(buffer_lines(vim.api.nvim_get_current_buf()))
  local lines = {
    "WordCount",
    "",
    "総文字数: " .. stats.total,
    "日本語: " .. stats.japanese,
    "英字: " .. stats.english,
    "数字: " .. stats.digits,
    "空白: " .. stats.whitespace,
    "記号・句読点: " .. stats.symbols,
    "その他: " .. stats.other,
    "行数: " .. stats.lines,
    "単語数: " .. stats.words,
  }
  local width = 0
  for _, line in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(line)) end
  width = math.min(width + 2, math.max(1, vim.o.columns))
  local height = math.min(#lines, math.max(1, vim.o.lines - 1))
  if detail_win and vim.api.nvim_win_is_valid(detail_win) then vim.api.nvim_win_close(detail_win, true) end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
  })
  detail_win = win
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, "<cmd>close<cr>", { buffer = buf, silent = true })
  end
  return win
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  vim.api.nvim_create_user_command("WordCount", M.details, {})
  vim.api.nvim_create_user_command("WordCountToggle", M.toggle, {})
  vim.api.nvim_create_user_command("WordCountRefresh", M.refresh, {})
  if detail_win and vim.api.nvim_win_is_valid(detail_win) then vim.api.nvim_win_close(detail_win, true) end
  display.close_all()
  local group = vim.api.nvim_create_augroup("WordCount", { clear = true })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    callback = function(args) schedule(args.buf) end,
  })
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "TabEnter", "WinResized", "VimResized" }, {
    group = group,
    callback = refresh_all,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(args)
      local win = tonumber(args.match)
      if not win then return end
      if display.is_counter(win) then
        display.remove_counter(win)
        return
      end
      if win == detail_win then detail_win = nil end
      -- Closing a window is not allowed inside WinClosed, so defer the cleanup.
      vim.schedule(function()
        display.close(win)
        refresh_all()
      end)
    end,
  })
  if M.config.enabled then M.enable() end
end

return M
