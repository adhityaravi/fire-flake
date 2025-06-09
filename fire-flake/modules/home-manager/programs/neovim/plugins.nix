{ pkgs, nurpkgs ? {} }:

let
  treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: with plugins; [
    bash
    go
    python
    terraform
    nix
    lua
    json
    yaml
    markdown
  ]);
in

with pkgs.vimPlugins; [
  # Core dependencies
  plenary-nvim
  nvim-web-devicons
  mini-nvim

  # UX
  which-key-nvim
  noice-nvim
  hydra-nvim
  auto-save-nvim
  nurpkgs.kulala-nvim
  nurpkgs.goose-nvim
  pkgs.vimPlugins.render-markdown-nvim

  # UI
  lualine-nvim
  toggleterm-nvim
  alpha-nvim
  persistence-nvim
  bufferline-nvim
  smart-splits-nvim
  leap-nvim
  indent-blankline-nvim
  # theme
  catppuccin-nvim
  rose-pine
  kanagawa-nvim
  oxocarbon-nvim
  everforest
  gruvbox-nvim
  nightfox-nvim
  dracula-nvim
  monokai-pro-nvim
  cyberdream-nvim

  # Syntax highlighting
  treesitter

  # LSP support
  nvim-lspconfig
  mason-nvim
  mason-lspconfig-nvim
  lspkind-nvim

  # Autocompletion
  nvim-cmp
  cmp-nvim-lsp
  cmp-buffer
  cmp-path
  cmp-cmdline
  cmp_luasnip
  copilot-cmp
  copilot-lua
  luasnip
  friendly-snippets
  nvim-autopairs
  nvim-spider

  # Formatting
  conform-nvim

  # Search and navigation
  telescope-nvim
  telescope-project-nvim
  telescope-file-browser-nvim
  nvim-spectre
  todo-comments-nvim
  grapple-nvim
  obsidian-nvim

  # File explorer
  nvim-tree-lua
  oil-nvim

  # Debugging
  nvim-dap
  nvim-dap-python
  nvim-dap-go
  nvim-dap-ui
  neotest
  neotest-go
  neotest-python
  neotest-plenary
  nvim-bqf

  # Git integration
  gitsigns-nvim
  lazygit-nvim
  octo-nvim
]
