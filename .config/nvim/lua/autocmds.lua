require "nvchad.autocmds"

local original_signature_help = vim.lsp.buf.signature_help

vim.lsp.buf.signature_help = function(opts)
  local clients = vim.lsp.get_clients { bufnr = 0 }
  local has_support = false

  for _, client in ipairs(clients) do
    local caps = client.server_capabilities
    if caps.textDocument and caps.textDocument.signatureHelp then
      has_support = true
      break
    end
  end

  if has_support then
    return original_signature_help(opts)
  end
end

vim.lsp.handlers["textDocument/definition"] = vim.lsp.with(
  vim.lsp.handlers["textDocument/definition"] or function() end,
  { silent = true }
)

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
  vim.lsp.handlers["textDocument/signatureHelp"] or function() end,
  { silent = true }
)
