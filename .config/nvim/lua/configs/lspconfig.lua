local lspconfig = require "lspconfig"

lspconfig.clangd.setup {
  -- You can add additional configurations here.
  cmd = { "clangd" },
  filetypes = { "c", "cpp", "objc", "objcpp", "cc", "h", "hh" },
  root_dir = lspconfig.util.root_pattern("compile_commands.json", "compile_flags.txt", ".git"),
}

-- Setup tsserver replacement: ts_ls
lspconfig.ts_ls.setup({
  on_attach = function(client, bufnr)
    -- Disable tsserver formatting if using ESLint or prettier for formatting
    client.server_capabilities.documentFormattingProvider = false
  end,
  root_dir = lspconfig.util.root_pattern("package.json", "tsconfig.json", "jsconfig.json", ".git"),
})

-- Setup ESLint language server
lspconfig.eslint.setup({
  on_attach = function(client, bufnr)
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      command = "EslintFixAll",
    })
  end,
})

lspconfig.zls.setup {
    cmd = { "zls" }, -- Or the full path to your zls binary
}

lspconfig.clangd.setup(require "configs.clangd")

lspconfig.gopls.setup({
  settings = {
    gopls = {
      usePlaceholders = true,
      staticcheck = true,
    },
  },
})

lspconfig.golangci_lint_ls.setup({
  cmd = { "golangci-lint-langserver" },
  filetypes = { "go", "gomod" },
  root_dir = lspconfig.util.root_pattern(".git", "go.mod"),
  init_options = {
    command = { "golangci-lint", "run", "--out-format", "json" },
  },
})

lspconfig.kotlin_language_server.setup({
  cmd = { "kotlin-language-server" }, -- optional, can be omitted with Mason
  filetypes = { "kotlin" },
  root_dir = lspconfig.util.root_pattern("settings.gradle", "settings.gradle.kts", "build.gradle", ".git"),
})

return lspconfig
