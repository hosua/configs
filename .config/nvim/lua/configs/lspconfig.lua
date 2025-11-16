require("nvchad.configs.lspconfig").defaults()

-- Enable inline diagnostics
vim.diagnostic.config({
  virtual_text = true,  -- Show error messages inline
  signs = true,         -- Show error signs in the gutter (left side)
  underline = true,     -- Underline problematic code
  update_in_insert = false,  -- Don't update while typing
  severity_sort = true,  -- Sort by error severity
})

local servers = { "html", "cssls", "eslint", "tsserver", "clangd" }
vim.lsp.enable(servers)

vim.lsp.config("eslint", {
  settings = {
    workingDirectory = { mode = "auto" },
    codeAction = {
      disableRuleComment = {
        enable = true,
        location = "separateLine",
      },
      showDocumentation = {
        enable = true,
      },
    },
  },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
})

-- read :h vim.lsp.config for changing options of lsp servers 
