require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<leader>sd", vim.diagnostic.open_float, { desc = "Show diagnostics under cursor" })
map("n", "<leader>sf", vim.lsp.buf.code_action, { desc = "Show/apply code fixes" })
map("n", "<leader>tt", function()
  require("base46").toggle_transparency()
end, { desc = "toggle transparency" })
