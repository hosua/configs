require "nvchad.autocmds"

local original_signature_help = vim.lsp.buf.signature_help

-- vim.lsp.buf.signature_help = function(opts)
--   local clients = vim.lsp.get_clients { bufnr = 0 }
--   local has_support = false
--
--   for _, client in ipairs(clients) do
--     local caps = client.server_capabilities
--     if caps.textDocument and caps.textDocument.signatureHelp then
--       has_support = true
--       break
--     end
--   end
--
--   if has_support then
--     return original_signature_help(opts)
--   end
-- end

local original_definition = vim.lsp.handlers["textDocument/definition"]
vim.lsp.handlers["textDocument/definition"] = function(err, result, ctx, config)
  return (original_definition or function() end)(err, result, ctx, vim.tbl_extend("force", config or {}, { silent = true }))
end

local original_signature_help_handler = vim.lsp.handlers["textDocument/signatureHelp"]
vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
  return (original_signature_help_handler or function() end)(err, result, ctx, vim.tbl_extend("force", config or {}, { silent = true }))
end
