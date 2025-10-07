vim.g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

-- Check if a given executable is available
local function executable(name)
  return vim.fn.executable(name) == 1
end

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
    config = function()
      require "options"
    end,
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "nvchad.autocmds"

vim.schedule(function()
  require "mappings"
end)

-- Prettier stuff

-- Format the buffer with Prettier
local function format_with_prettier()
  if executable "prettier" then
    vim.cmd("silent !prettier --write " .. vim.fn.expand "%:p")
  else
    print "Prettier is not installed"
  end
end

-- Create an augroup for Prettier
local augroup = vim.api.nvim_create_augroup("PrettierFormat", { clear = true })

-- Set up an autocmd for formatting on save
vim.api.nvim_create_autocmd("BufWritePost", {
  group = augroup,
  pattern = { "*.js", "*.jsx", "*.ts", "*.tsx", "*.css", "*.scss", "*.html", "*.json", "*.md" },
  callback = format_with_prettier,
})
