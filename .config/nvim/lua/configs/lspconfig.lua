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

local servers =
  { "html", "cssls", "eslint", "vtsls", "clangd", "rust_analyzer", "bashls", "gopls", "ruff", "basedpyright" }

local lsp = vim.lsp

lsp.enable(servers)

lsp.config("bashls", {
  settings = {
    bashIde = {
      globPattern = "*@(.sh|.inc|.bash|.command)",
    },
  },
})

lsp.config("basedpyright", {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = {
    "pyrightconfig.json",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    ".git",
  },
  settings = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly",
        useLibraryCodeForTypes = true,
      },
    },
  },
})

lsp.config("ruff", {
  cmd = { "basedpyright-langserver", "--stdio" },
  settings = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly",
        useLibraryCodeForTypes = true,
      },
    },
  },
  root_markers = {
    "pyrightconfig.json",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    ".git",
  },
  filetypes = { "python" },
})

lsp.config("gopls", {
  settings = {},
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
})

lsp.config("eslint", {
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

lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      diagnostics = {
        enable = false,
      },
    },
  },
})

lsp.config("vtsls", {
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
