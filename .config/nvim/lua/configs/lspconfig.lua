require("nvchad.configs.lspconfig").defaults()

-- Enable inline diagnostics
vim.diagnostic.config({
  virtual_text = true,  -- Show error messages inline
  signs = true,         -- Show error signs in the gutter (left side)
  underline = true,     -- Underline problematic code
  update_in_insert = false,  -- Don't update while typing
  severity_sort = true,  -- Sort by error severity
})

local servers = { "html", "cssls", "eslint", "ts_ls", "clangd" }
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

-- Configure typescript-language-server for library imports
vim.lsp.config("ts_ls", {
  root_dir = function(fname)
    local util = require("lspconfig.util")
    return util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git")(fname) or vim.fs.dirname(fname)
  end,
  settings = {
    typescript = {
      preferences = {
        includePackageJsonAutoImports = "on",
        importModuleSpecifier = "auto",
        importModuleSpecifierEnding = "minimal",
      },
      suggest = {
        autoImports = true,
        includeCompletionsForModuleExports = true,
      },
    },
    javascript = {
      preferences = {
        includePackageJsonAutoImports = "on",
        importModuleSpecifier = "auto",
        importModuleSpecifierEnding = "minimal",
      },
      suggest = {
        autoImports = true,
        includeCompletionsForModuleExports = true,
      },
    },
  },
  -- Disable formatting if using ESLint/prettier (like your old config)
  on_attach = function(client, bufnr)
    client.server_capabilities.documentFormattingProvider = false
  end,
})

-- read :h vim.lsp.config for changing options of lsp servers 
