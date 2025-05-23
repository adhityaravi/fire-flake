-- General settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.fillchars:append { vert = "│" } -- or "┃", "▕", etc.

-- Load all plugin configs - order matters
-- #todo: lazyload
require("plugins.colorscheme").load()
require("plugins.treesitter")
require("plugins.lsp")
require("plugins.cmp")
require("plugins.telescope")
require("plugins.nvimtree")
require("plugins.dap")
require("plugins.neotest")
require("plugins.git")
require("plugins.alpha")
require("plugins.persistence")
require("plugins.lualine")
require("plugins.bufferline")
require("plugins.copilot")
require("plugins.toggleterm")
require("plugins.smartsplits")
require("plugins.spectre")
require("plugins.grapple")
require("plugins.leap")
require("plugins.octo")
-- require("plugins.miniclue")  -- whichkey alternative
require("plugins.noice")
require("plugins.autosave")
require("plugins.bqf")
require("keymap")
require("plugins.hydra")

