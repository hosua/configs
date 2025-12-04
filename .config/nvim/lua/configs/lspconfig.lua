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
local ts_restart_count = {}
local MAX_RESTART_ATTEMPTS = 3
local RESTART_DELAY_MS = 2000

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
  end,

  on_exit = function(code, signal, client_id)
    local root = vim.fn.getcwd()
    ts_restart_count[root] = (ts_restart_count[root] or 0) + 1

    if code ~= 0 and signal ~= 15 then
      if ts_restart_count[root] <= MAX_RESTART_ATTEMPTS then
        vim.notify(
          string.format(
            "TypeScript server exited unexpectedly (code: %d, signal: %d). Restarting... (%d/%d)",
            code,
            signal,
            ts_restart_count[root],
            MAX_RESTART_ATTEMPTS
          ),
          vim.log.levels.WARN
        )

        vim.defer_fn(function()
          local bufnr = vim.api.nvim_get_current_buf()
          local filetype = vim.bo[bufnr].filetype
          if vim.tbl_contains({ "typescript", "typescriptreact", "javascript", "javascriptreact" }, filetype) then
            local active = vim.lsp.get_active_clients({ name = "ts_ls", bufnr = bufnr })
            if #active == 0 then
              local config = vim.lsp.config.get("ts_ls")
              if config then
                vim.lsp.start(config, { bufnr = bufnr })
              end
            end
          end
        end, RESTART_DELAY_MS)
      else
        vim.notify(
          string.format(
            "TypeScript server crashed too many times (%d attempts). Manual restart required.",
            ts_restart_count[root]
          ),
          vim.log.levels.ERROR
        )
        ts_restart_count[root] = 0
      end
    else
      ts_restart_count[root] = 0
    end
  end,
})

-- read :h vim.lsp.config for changing options of lsp servers
