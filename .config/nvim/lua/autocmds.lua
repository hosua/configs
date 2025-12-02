require "nvchad.autocmds"

vim.api.nvim_clear_autocmds({ event = "TextChangedI", pattern = "*" })

vim.api.nvim_create_autocmd("TextChangedI", {
  pattern = "*",
  callback = function()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    for _, client in ipairs(clients) do
      if client.server_capabilities.signatureHelpProvider then
        vim.lsp.buf.signature_help()
        break
      end
    end
  end,
  desc = "Show signature help if supported",
})
