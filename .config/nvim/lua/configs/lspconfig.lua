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
    local root_dir = make_root_finder({
      "eslint.config.js",
      "eslint.config.mjs",
      "eslint.config.cjs",
      "automation/eslint.config.mjs",
      "package.json",
      ".git",
    })(buf_path())

    local joinpath = vim.fs.joinpath
    -- Try to locate repo root via .git to resolve shared config path
    local repo_root = (function()
      local gitdir = vim.fs.find({ ".git" }, { upward = true, path = root_dir })[1]
      return gitdir and vim.fs.dirname(gitdir) or root_dir
    end)()

    local config_abs = joinpath(repo_root, "automation", "eslint.config.mjs")
    local uv = vim.uv or vim.loop
    local has_config = uv.fs_stat(config_abs) ~= nil
    local env = {}
    if has_config then
      env.ESLINT_USE_FLAT_CONFIG = "true"
      env.ESLINT_CONFIG_PATH = config_abs
    end

    start_lsp("eslint", {
      cmd = { "vscode-eslint-language-server", "--stdio" },
      root_dir = root_dir,
      cmd_cwd = root_dir,
      cmd_env = env,
      settings = {
        -- Match vscode-eslint expected settings keys
        -- Enable diagnostics and support flat config
        validate = "on",
        run = "onType",
        format = false,
        workingDirectory = { mode = "auto" },
        codeAction = {
          disableRuleComment = { enable = true },
          showDocumentation = { enable = true },
        },
        experimental = has_config and { useFlatConfig = true } or nil,
      },
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

-- return nothing; this file is sourced for side-effects only
