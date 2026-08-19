require "nvchad.options"

-- add yours here!

local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!
o.relativenumber = true
o.clipboard = "unnamedplus"

-- Re-enable the Python 3 provider (NvChad disables it in nvchad.options) so
-- python-based plugins like vim-latex-live-preview can define their commands.
vim.g.loaded_python3_provider = nil
vim.g.python3_host_prog = "/usr/sbin/python3" -- interpreter that has pynvim installed
