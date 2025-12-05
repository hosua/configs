require("nvchad.configs.lspconfig").defaults()

-- :help lspconfig-all to see default lsp configurations

-- Enable inline diagnostics
vim.diagnostic.config {
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
}

-- Increase memory for TypeScript server
vim.env.NODE_OPTIONS = vim.env.NODE_OPTIONS or "--max_old_space_size=4096"

local servers = { "html", "cssls", "eslint", "vtsls", "clangd", "rust_analyzer", "bashls" }
vim.lsp.enable(servers)

vim.lsp.config("bashls", {
  settings = {
    bashIde = {
      globPattern = "*@(.sh|.inc|.bash|.command)",
    },
  },
})

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

vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      diagnostics = {
        enable = false,
      },
    },
  },
})

vim.lsp.config("vtsls", {
  settings = {
    typescript = {
      validate = { enable = true },
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

  on_attach = function(client, bufnr)
    client.server_capabilities.documentFormattingProvider = false
  end,
})
