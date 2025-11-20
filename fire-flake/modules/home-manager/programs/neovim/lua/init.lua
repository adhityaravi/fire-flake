-- General settings
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- -- Add fire-flake lua directory to runtime path for our custom modules
-- local fire_flake_lua = "/home/ivdi/Repo/fire-flake/fire-flake/modules/home-manager/programs/neovim/lua"
-- if vim.fn.isdirectory(fire_flake_lua) == 1 then
--   package.path = package.path .. ";" .. fire_flake_lua .. "/?.lua"
--   package.path = package.path .. ";" .. fire_flake_lua .. "/?/init.lua"
-- end

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.fillchars:append({ vert = "│" }) -- or "┃", "▕", etc.
vim.o.shell = "fish" -- Set default shell to fish

-- Load saved colorscheme or use default
local colorscheme_file = vim.fn.stdpath("state") .. "/colorscheme"
local colorscheme = "doom-one" -- default

if vim.fn.filereadable(colorscheme_file) == 1 then
  local saved = vim.fn.readfile(colorscheme_file)[1]
  if saved and #saved > 0 then
    colorscheme = saved
  end
end

vim.cmd([[colorscheme ]] .. colorscheme)

-- Save colorscheme whenever it changes
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    local current = vim.g.colors_name
    if current then
      vim.fn.writefile({ current }, colorscheme_file)
    end
  end,
})

-- Load all plugin configs - order matters
-- #todo: lazyload

-- UI plugins that must initialize on startup
require("plugins.explorer.oil")
require("plugins.ui.alpha")

-- helper for lazy loading modules on events
local function lazy_require(event, module, opts)
  vim.api.nvim_create_autocmd(
    event,
    vim.tbl_extend("force", opts or {}, {
      once = true,
      callback = function()
        require(module)
      end,
    })
  )
end

-- core plugins
lazy_require("BufReadPost", "plugins.syntax.treesitter")
lazy_require("BufReadPost", "plugins.lsp")
lazy_require("InsertEnter", "plugins.completion.cmp")

-- fire VeryLazy event shortly after UI loads
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.defer_fn(function()
      vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
    end, 100)
  end,
})

-- plugins that can wait
local lazy_plugins = {
  "plugins.search.telescope",
  "plugins.explorer.nvimtree",
  "plugins.debug.dap",
  "plugins.debug.neotest",
  "plugins.git.git",
  "plugins.ui.persistence",
  "plugins.ui.lualine",
  "plugins.ui.bufferline",
  "plugins.completion.copilot",
  "plugins.completion.luasnip",
  "plugins.ui.toggleterm",
  "plugins.completion.autopairs",
  "plugins.ui.smartsplits",
  "plugins.search.spectre",
  "plugins.search.grapple",
  -- "plugins.notes.obsidian",
  "plugins.completion.spider",
  "plugins.search.todocomments",
  "plugins.formatting.conform",
  "plugins.ui.indentblankline",
  "plugins.ui.smear-cursor",
  "plugins.git.octo",
  "plugins.ux.noice",
  "plugins.ux.autosave",
  -- "plugins.ux.kulala",
  -- "plugins.ux.goose",
  "plugins.debug.bqf",
  "plugins.ux.hydra",
  "plugins.ux.whichkey",
  -- require("plugins.ux.miniclue")  -- whichkey alternative
}

for _, mod in ipairs(lazy_plugins) do
  lazy_require("User", mod, { pattern = "VeryLazy" })
end
