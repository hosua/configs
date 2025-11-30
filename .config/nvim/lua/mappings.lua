require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<leader>sd", vim.diagnostic.open_float, { desc = "Show diagnostics under cursor" })
map("n", "<leader>sf", vim.lsp.buf.code_action, { desc = "Show/apply code fixes" })

local format_on_save_enabled = true -- Track state ourselves

map("n", "<leader>tf", function()
  local conform = require "conform"
  format_on_save_enabled = not format_on_save_enabled

  if format_on_save_enabled then
    conform.setup { format_on_save = { timeout_ms = 500, lsp_fallback = true } }
    vim.notify("Format on save: ENABLED", vim.log.levels.INFO)
  else
    conform.setup { format_on_save = false }
    vim.notify("Format on save: DISABLED", vim.log.levels.INFO)
  end
end, { desc = "Toggle format on save" })

map({ "n", "i" }, "<leader>sm", function()
  local MAX_MESSAGES = 50

  local msgs = vim.fn.execute "messages"
  local lines = vim.split(msgs, "\n")

  local reversed_lines = {}
  for i = #lines, math.max(#lines - MAX_MESSAGES + 1, 1), -1 do
    table.insert(reversed_lines, lines[i])
  end

  vim.cmd "botright new"
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, reversed_lines)

  local bo = vim.bo
  bo.buftype = "nofile"
  bo.bufhidden = "wipe"
  bo.swapfile = false
  bo.modifiable = false

  vim.api.nvim_win_set_height(0, 15)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end, { desc = "Show messages in bottom pane" })

map({ "n", "i" }, "<leader>tt", function()
  require("base46").toggle_transparency()
end, { desc = "toggle transparency" })
