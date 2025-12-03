require("nvchad.configs.lspconfig").defaults()

-- Enable inline diagnostics
vim.diagnostic.config {
  virtual_text = true, -- Show error messages inline
  signs = true, -- Show error signs in the gutter (left side)
  underline = true, -- Underline problematic code
  update_in_insert = false, -- Don't update while typing
  severity_sort = true, -- Sort by error severity
}

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

-- Configure ts_ls - ensure settings are applied
vim.lsp.config("ts_ls", {
  root_dir = function(fname)
    local util = require "lspconfig.util"

    -- Ensure fname is a string
    if not fname or type(fname) ~= "string" then
      fname = vim.api.nvim_buf_get_name(0) or ""
    end

    -- Try to find root using patterns
    local root = util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git")(fname)

    -- Fallback to dirname if root not found, but ensure fname is valid
    if root then
      return root
    elseif fname and fname ~= "" then
      return vim.fs.dirname(fname)
    else
      -- Last resort: return current working directory
      return vim.fn.getcwd()
    end
  end,

  settings = {
    typescript = {
      validate = { enable = true },
      diagnostics = {
        globals = {},
      },
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
    -- Force update settings after attach
    client.notify("workspace/didChangeConfiguration", {
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
    })
  end,
})

-- read :h vim.lsp.config for changing options of lsp servers
