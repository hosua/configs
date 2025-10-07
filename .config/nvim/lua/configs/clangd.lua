return {
  cmd = { "clangd", "--compile-commands-dir=." }, -- or path to your JSON
  filetypes = { "c", "cpp", "objc", "objcpp" },
  root_dir = require("lspconfig.util").root_pattern("compile_commands.json", ".git"),
}
