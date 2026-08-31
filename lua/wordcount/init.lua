local count = require("wordcount.count")
local display = require("wordcount.display")
local M = { config = { enabled = true, position = "top_right", debounce_ms = 100, format = "文字数: %d", markdown = { include_frontmatter = true } }, enabled = false }

local function buffer_lines(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  if vim.bo[buf].filetype == "markdown" and not M.config.markdown.include_frontmatter then
    return count.remove_frontmatter(lines)
  end
  return lines
end

local function refresh_window(winid)
  if not M.enabled or not vim.api.nvim_win_is_valid(winid) or display.is_counter(winid) then return end
  local buf = vim.api.nvim_win_get_buf(winid)
  if vim.bo[buf].buftype ~= "" then
    display.close(winid)
    return
  end
  local stats = count.count(buffer_lines(buf))
  display.show(winid, string.format(M.config.format, stats.total), M.config.position)
end

local function refresh_now()
  refresh_window(vim.api.nvim_get_current_win())
end

local function refresh_all()
  if not M.enabled then return end
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    refresh_window(winid)
  end
end

local function schedule()
  if not M.enabled then return end
  if not M.timer then M.timer = (vim.uv or vim.loop).new_timer() end
  M.timer:stop(); M.timer:start(M.config.debounce_ms, 0, vim.schedule_wrap(refresh_all))
end
function M.refresh() refresh_now() end
function M.enable() M.enabled = true; refresh_all() end
function M.disable() M.enabled = false; display.close_all() end
function M.toggle() if M.enabled then M.disable() else M.enable() end end
function M.details()
  local s = count.count(buffer_lines(vim.api.nvim_get_current_buf())); local lines = { "WordCount", "", "総文字数: " .. s.total, "日本語: " .. s.japanese, "英字: " .. s.english, "数字: " .. s.digits, "空白: " .. s.whitespace, "記号・句読点: " .. s.symbols, "その他: " .. s.other, "行数: " .. s.lines, "単語数: " .. s.words }; local width = 0
  for _, line in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(line)) end
  local buf = vim.api.nvim_create_buf(false, true); vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines); vim.bo[buf].modifiable = false; vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(buf, true, { relative = "editor", row = math.max(0, math.floor((vim.o.lines - #lines) / 2) - 1), col = math.max(0, math.floor((vim.o.columns - width - 2) / 2)), width = width + 2, height = #lines, style = "minimal", border = "rounded" })
  for _, key in ipairs({ "q", "<Esc>" }) do vim.keymap.set("n", key, "<cmd>close<cr>", { buffer = buf, silent = true }) end; return win
end
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {}); vim.api.nvim_create_user_command("WordCount", M.details, {}); vim.api.nvim_create_user_command("WordCountToggle", M.toggle, {}); vim.api.nvim_create_user_command("WordCountRefresh", M.refresh, {})
  display.close_all()
  local group = vim.api.nvim_create_augroup("WordCount", { clear = true }); vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, { group = group, callback = schedule }); vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "WinScrolled", "VimResized" }, { group = group, callback = refresh_all }); vim.api.nvim_create_autocmd("WinClosed", { group = group, callback = function(args) local win = tonumber(args.match); if display.is_counter(win) then display.remove_counter(win) else vim.schedule(refresh_all) end end }); if M.config.enabled then M.enable() end
end
return M
