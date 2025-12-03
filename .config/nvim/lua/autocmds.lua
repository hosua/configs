require "nvchad.autocmds"

local augroup = vim.api.nvim_create_augroup("SafeLSP", { clear = true })

local function safe_signature_help()
  local ok, _ = pcall(function()
    local clients = vim.lsp.get_clients { bufnr = 0 }
    if #clients == 0 then
      return
    end

    local has_support = false
    for _, client in ipairs(clients) do
      local caps = client.server_capabilities
      if caps.textDocument and caps.textDocument.signatureHelp then
        has_support = true
        break
      end
    end

    if has_support then
      vim.lsp.buf.signature_help()
    end
  end)
  if not ok then
    return
  end
end

vim.api.nvim_create_autocmd("TextChangedI", {
  group = augroup,
  callback = safe_signature_help,
  desc = "Safely trigger signature help if supported",
})

vim.lsp.handlers["textDocument/definition"] = vim.lsp.with(
  vim.lsp.handlers["textDocument/definition"] or function() end,
  { silent = true }
)

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
  vim.lsp.handlers["textDocument/signatureHelp"] or function() end,
  { silent = true }
)
