-- Neovim 0.11+ LSP setup without lspconfig (uses vim.lsp.start + autocmds)

local function buf_path()
  return vim.api.nvim_buf_get_name(0)
end

local function make_root_finder(patterns)
  return function(startpath)
    local path = startpath or buf_path()
    local found = vim.fs.find(patterns, { upward = true, path = path })[1]
    return found and vim.fs.dirname(found) or vim.fn.getcwd()
  end
end

local function start_lsp(name, config)
  config = config or {}
  config.name = name
  vim.lsp.start(config)
end

-- clangd
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp", "objc", "objcpp", "cc", "h", "hh" },
  callback = function()
    start_lsp("clangd", {
      cmd = { "clangd" },
      root_dir = make_root_finder({ "compile_commands.json", "compile_flags.txt", ".git" })(buf_path()),
    })
  end,
})

-- TypeScript/JavaScript (tsserver via typescript-language-server)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  callback = function()
    start_lsp("tsserver", {
      cmd = { "typescript-language-server", "--stdio" },
      root_dir = make_root_finder({ "package.json", "tsconfig.json", "jsconfig.json", ".git" })(buf_path()),
      on_attach = function(client)
        client.server_capabilities.documentFormattingProvider = false
      end,
    })
  end,
})

-- ESLint
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  callback = function()
    start_lsp("eslint", {
      cmd = { "vscode-eslint-language-server", "--stdio" },
      root_dir = make_root_finder({ "package.json", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json", ".git" })(buf_path()),
      on_attach = function(_, bufnr)
        vim.api.nvim_create_autocmd("BufWritePre", { buffer = bufnr, command = "EslintFixAll" })
      end,
    })
  end,
})

-- Zig
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "zig" },
  callback = function()
    start_lsp("zls", { cmd = { "zls" } })
  end,
})

-- Go (gopls)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "gomod" },
  callback = function()
    start_lsp("gopls", {
      cmd = { "gopls" },
      settings = { gopls = { usePlaceholders = true, staticcheck = true } },
      root_dir = make_root_finder({ "go.mod", ".git" })(buf_path()),
    })
  end,
})

-- golangci-lint language server
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "gomod" },
  callback = function()
    start_lsp("golangci-lint", {
      cmd = { "golangci-lint-langserver" },
      init_options = { command = { "golangci-lint", "run", "--out-format", "json" } },
      root_dir = make_root_finder({ "go.mod", ".git" })(buf_path()),
    })
  end,
})

-- Kotlin
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "kotlin" },
  callback = function()
    start_lsp("kotlin-language-server", {
      cmd = { "kotlin-language-server" },
      root_dir = make_root_finder({ "settings.gradle", "settings.gradle.kts", "build.gradle", ".git" })(buf_path()),
    })
  end,
})

-- Rust
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "rust" },
  callback = function()
    start_lsp("rust-analyzer", {
      cmd = { "rust-analyzer" },
      root_dir = make_root_finder({ "Cargo.toml", ".git" })(buf_path()),
      settings = {
        ["rust-analyzer"] = {
          cargo = { allFeatures = true },
          checkOnSave = { command = "clippy" },
        },
      },
    })
  end,
})

-- PHP (phpactor)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "php" },
  callback = function()
    start_lsp("phpactor", {
      cmd = { "phpactor", "language-server" },
      root_dir = make_root_finder({ "composer.json", ".git" })(buf_path()),
    })
  end,
})

-- return nothing; this file is sourced for side-effects only
