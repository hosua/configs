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
--
local original_definition = vim.lsp.handlers["textDocument/definition"]
vim.lsp.handlers["textDocument/definition"] = function(err, result, ctx, config)
  return (original_definition or function() end)(err, result, ctx, vim.tbl_extend("force", config or {}, { silent = true }))
end

local original_signature_help_handler = vim.lsp.handlers["textDocument/signatureHelp"]
vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
  return (original_signature_help_handler or function() end)(err, result, ctx, vim.tbl_extend("force", config or {}, { silent = true }))
end

vim.api.nvim_create_autocmd("LspDetach", {
  group = vim.api.nvim_create_augroup("TypeScriptRestart", { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.name == "ts_ls" then
      local bufnr = event.buf
      local filetype = vim.bo[bufnr].filetype
      if vim.tbl_contains({ "typescript", "typescriptreact", "javascript", "javascriptreact" }, filetype) then
        vim.defer_fn(function()
          local active_clients = vim.lsp.get_active_clients({ name = "ts_ls", bufnr = bufnr })
          if #active_clients == 0 then
            vim.notify("TypeScript server detached. Use :LspRestart to restart.", vim.log.levels.INFO)
          end
        end, 1000)
      end
    end
  end,
})
