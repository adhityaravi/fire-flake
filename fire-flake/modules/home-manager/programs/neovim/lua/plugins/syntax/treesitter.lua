-- Ensure parser directory exists
local parser_dir = vim.fn.stdpath("data") .. "/treesitter"
vim.fn.mkdir(parser_dir, "p")

require('nvim-treesitter.configs').setup {
  -- treesitter dependencies are installed through nix. refer modules/home-manager/programs/neovim/plugins.nix for actual treesitter dependencies.
  auto_install = false,   -- prevents runtime install attempts

  -- Explicitly set parser install directory to prevent Nix store write attempts
  parser_install_dir = parser_dir,

  highlight = { enable = true },
  indent = { enable = true },
}
