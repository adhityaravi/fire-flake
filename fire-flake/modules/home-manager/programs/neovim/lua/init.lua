-- General settings
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Add fire-flake lua directory to runtime path for our custom modules
local fire_flake_lua = "/home/ivdi/Repo/fire-flake/fire-flake/modules/home-manager/programs/neovim/lua"
if vim.fn.isdirectory(fire_flake_lua) == 1 then
  package.path = package.path .. ";" .. fire_flake_lua .. "/?.lua"
  package.path = package.path .. ";" .. fire_flake_lua .. "/?/init.lua"
end

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

-- Initialize NvChad Base46 theme system if available
-- Set up Base46 cache directory BEFORE requiring base46
local cache_dir = vim.fn.stdpath("cache") .. "/base46/"
vim.g.base46_cache = cache_dir
vim.fn.mkdir(cache_dir, "p")

-- Create complete nvconfig BEFORE requiring base46
local nvconfig_data = {
  base46 = {
    theme = "catppuccin", -- default theme
    transparency = false,
    integrations = {},
    hl_override = {},
    hl_add = {},
    changed_themes = {}
  },
  ui = {
    cmp = {
      icons = true,
      lspkind_text = true,
      style = "default",
      selected_item_bg = "colored"
    },
    telescope = { style = "borderless" },
    statusline = {
      theme = "default",
      separator_style = "default",
      order = nil,
      modules = nil
    },
    tabufline = {
      enabled = true,
      lazyload = true,
      order = { "treeOffset", "buffers", "tabs", "btns" },
      modules = nil
    },
    nvdash = {
      load_on_startup = false,
      header = {
        "           ▄ ▄                   ",
        "       ▄   ▄▄▄     ▄ ▄▄▄ ▄ ▄     ",
        "       █ ▄ █▄█ ▄▄▄ █ █▄█ █ █     ",
        "    ▄▄ █▄█▄▄▄█ █▄█▄█▄▄█▄▄█ █     ",
        "  ▄ █▄▄█ ▄ ▄▄ ▄█ ▄▄▄▄▄▄▄▄▄▄▄▄▄▄  ",
        "  █▄▄▄▄ ▄▄▄ █ ▄ ▄▄▄ ▄ ▄▄▄ ▄ ▄ █ ▄",
        "▄ █ █▄█ █▄█ █ █ █▄█ █ █▄█ ▄▄▄ █ █",
        "█▄█ ▄ █▄▄█▄▄█ █ ▄▄█ █ ▄ █ █▄█▄█ █",
        "    █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█ █▄█▄▄▄█    ",
      },
      buttons = {
        { "  Find File", "Spc f f", "Telescope find_files" },
        { "󰈚  Recent Files", "Spc f o", "Telescope oldfiles" },
        { "󰈭  Find Word", "Spc f w", "Telescope live_grep" },
        { "  Bookmarks", "Spc m a", "Telescope marks" },
        { "  Themes", "Spc t h", "Telescope themes" },
        { "  Mappings", "Spc c h", "NvCheatsheet" },
      }
    }
  },
  lsp = { 
    signature = true 
  },
  term = {
    winopts = { number = false, relativenumber = false },
    sizes = { sp = 0.3, vsp = 0.2, ["bo sp"] = 0.3, ["bo vsp"] = 0.2 },
    float = {
      relative = "editor",
      row = 0.3,
      col = 0.25,
      width = 0.5,
      height = 0.4,
      border = "single",
    },
  },
  cheatsheet = {
    theme = "grid",
    excluded_groups = { "terminal (t)", "autopairs", "Nvim", "Opens" },
  },
  mason = { 
    cmd = true, 
    pkgs = {} 
  }
}

-- Store reference globally and make require("nvconfig") return the same table
_G.nvconfig = nvconfig_data
package.loaded["nvconfig"] = nvconfig_data

local has_base46, base46_err = pcall(require, "base46")
-- Base46 loaded silently

-- Load saved NvChad theme
local function load_saved_theme()
  local theme_path = vim.fn.stdpath("state") .. "/nvchad_theme"
  if vim.fn.filereadable(theme_path) == 1 then
    local theme = vim.fn.readfile(theme_path)[1]
    if theme and #theme > 0 then
      -- Update both nvconfig and chadrc
      require("nvconfig").base46.theme = theme
      local has_chadrc, chadrc = pcall(require, "chadrc")
      if has_chadrc then
        chadrc.base46.theme = theme
      end
      
      -- Apply the theme
      local has_base46, base46 = pcall(require, "base46")
      if has_base46 then
        base46.load_all_highlights()
      end
    end
  end
end

load_saved_theme()

-- Create Themes command for NvChad themes UI
vim.api.nvim_create_user_command("Themes", function(args)
  local has_themes, themes = pcall(require, "nvchad.themes")
  if not has_themes then
    vim.notify("NvChad themes not available - using telescope fallback", vim.log.levels.WARN)
    vim.cmd("Telescope themes")
    return
  end
  
  local style = args.args and #args.args > 0 and args.args or "bordered"
  themes.open({ style = style })
end, {
  nargs = "?",
  complete = function()
    return { "flat", "compact", "bordered" }
  end,
  desc = "Open NvChad themes UI (flat, compact, or bordered)"
})

-- Load all plugin configs - order matters
-- #todo: lazyload

-- UI plugins that must initialize on startup
require("plugins.explorer.oil")
require("plugins.ui.alpha")  -- Keep alpha for now until NvChad integration is stable

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
  "plugins.ui.lualine",       -- Restored until NvChad integration is stable
  "plugins.ui.bufferline",    -- Restored until NvChad integration is stable
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
  "plugins.ui.leap",
  "plugins.git.octo",
  "plugins.ux.noice",
  "plugins.ux.autosave",
  "plugins.ux.kulala",
  "plugins.ux.goose",
  "plugins.debug.bqf",
  "plugins.ux.hydra",
  "plugins.ux.whichkey",
  -- require("plugins.ux.miniclue")  -- whichkey alternative
}

for _, mod in ipairs(lazy_plugins) do
  lazy_require("User", mod, { pattern = "VeryLazy" })
end
