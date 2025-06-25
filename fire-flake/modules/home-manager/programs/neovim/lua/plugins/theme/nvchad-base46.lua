-- NvChad Base46 Theme System Integration
-- This replaces your existing multi-theme setup with NvChad's unified theme system

-- Set up Base46 first
require("base46").load_all_highlights()

-- Base46 configuration
local base46 = require("base46")

-- Initialize with a default theme (you can change this)
local default_theme = "onedark"

-- Load the theme
base46.toggle_theme(default_theme)

-- Theme picker function (replaces your existing colorscheme picker)
local function nvchad_theme_picker()
  local themes = base46.get_theme_tb()
  local theme_names = {}
  
  for theme_name, _ in pairs(themes) do
    table.insert(theme_names, theme_name)
  end
  
  -- Use telescope for theme selection
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  
  pickers.new({}, {
    prompt_title = "🎨 NvChad Themes",
    finder = finders.new_table {
      results = theme_names,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        if selection then
          base46.toggle_theme(selection.value)
          -- Persist the theme choice
          vim.g.nvchad_theme = selection.value
          -- You could also write to a file for persistence across sessions
        end
        actions.close(prompt_bufnr)
      end)
      return true
    end,
  }):find()
end

-- Create user command for theme picker
vim.api.nvim_create_user_command("NvChadThemes", nvchad_theme_picker, {
  desc = "Open NvChad theme picker"
})

-- Preserve your existing colorscheme persistence logic if you want
-- You can integrate this with your existing theme persistence system
local theme_file = vim.fn.stdpath("data") .. "/nvchad_theme.txt"

-- Load saved theme on startup
local function load_saved_theme()
  local file = io.open(theme_file, "r")
  if file then
    local saved_theme = file:read("*line")
    file:close()
    if saved_theme and saved_theme ~= "" then
      base46.toggle_theme(saved_theme)
      vim.g.nvchad_theme = saved_theme
    end
  end
end

-- Save theme when changed
local function save_theme(theme)
  local file = io.open(theme_file, "w")
  if file then
    file:write(theme)
    file:close()
  end
end

-- Auto-save theme when changed
vim.api.nvim_create_autocmd("User", {
  pattern = "Base46ThemeChange",
  callback = function()
    if vim.g.nvchad_theme then
      save_theme(vim.g.nvchad_theme)
    end
  end,
})

-- Load saved theme on startup
load_saved_theme()

-- Available themes (for reference):
-- ayu_dark, ayu_light, bearded-arc, blossom_light, catppuccin, 
-- chocolate, chadracula, dark_horizon, decay, doomchad, everblush, 
-- everforest, falcon, flex-light, github_dark, github_light, gruvbox, 
-- gruvchad, jabuti, jellybeans, kanagawa, material-darker, material-lighter,
-- melange, monochrome, nightfox, nightlamp, nightowl, nord, oceanic-next,
-- onedark, one_light, onenord, onenord_light, palenight, pastelDark, 
-- pastelbeans, penumbra_dark, penumbra_light, radium, rosepine, 
-- rosepine_dawn, solarized_dark, solarized_light, sweet_dark, tokyodark, 
-- tokyonight, tomorrow_night, vscode_dark, wombat, yoru

return {
  theme_picker = nvchad_theme_picker,
  current_theme = function() return vim.g.nvchad_theme or default_theme end,
}