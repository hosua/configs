require "nvchad.autocmds"

local augroup = vim.api.nvim_create_augroup("SafeSignatureHelp", { clear = true })

local function safe_signature_help()
  local ok, _ = pcall(function()
    local clients = vim.lsp.get_clients { bufnr = 0 }
    if #clients == 0 then
      return
    end

    local has_support = false
    for _, client in ipairs(clients) do
      if client.server_capabilities.signatureHelpProvider then
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
