-- NvChad Telescope Themes Extension
-- Based on NvChad's official theme switcher

local M = {}

-- Get all available NvChad themes
local function get_themes()
  local themes = {}
  
  -- Get theme files from Base46
  local theme_path = "/nix/store/7xg81hp0jk2kb295ys1n51bx9cr7dxp5-vimplugin-nvchad-base46-2.5/lua/base46/themes/"
  local handle = io.popen("ls " .. theme_path .. "*.lua 2>/dev/null")
  if handle then
    for line in handle:lines() do
      local theme_name = line:match("([^/]+)%.lua$")
      if theme_name then
        table.insert(themes, theme_name)
      end
    end
    handle:close()
  end
  
  -- Sort themes alphabetically
  table.sort(themes)
  
  return themes
end

-- Theme switcher function
local function switch_theme(theme_name)
  local nvconfig = require("nvconfig")
  
  -- Update theme in nvconfig
  nvconfig.base46.theme = theme_name
  vim.g.nvchad_theme = theme_name
  
  -- Reload Base46 highlights
  local base46 = require("base46")
  base46.load_all_highlights()
  
  -- Update lualine if available
  pcall(function()
    if _G.get_nvchad_lualine_theme then
      require("lualine").setup({
        options = { theme = _G.get_nvchad_lualine_theme() }
      })
    end
  end)
  
  -- Save theme preference
  local colorscheme_mod = require("plugins.theme.colorscheme")
  colorscheme_mod.save(theme_name, true)
  
  vim.notify("✓ Switched to NvChad theme: " .. theme_name, vim.log.levels.INFO)
end

-- Create the telescope picker
function M.themes()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")
  
  local themes = get_themes()
  local current_theme = require("nvconfig").base46.theme
  
  pickers.new({}, {
    prompt_title = "🎨 NvChad Themes",
    finder = finders.new_table {
      results = themes,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry == current_theme and entry .. " (current)" or entry,
          ordinal = entry,
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Theme Preview",
      define_preview = function(self, entry)
        local theme_name = entry.value
        local lines = {
          "Theme: " .. theme_name,
          "",
          "Preview colors:",
          "",
        }
        
        -- Try to get theme colors for preview
        local ok, theme_data = pcall(require, "base46.themes." .. theme_name)
        if ok and theme_data.base_30 then
          local colors = theme_data.base_30
          table.insert(lines, "Background: " .. (colors.black or "N/A"))
          table.insert(lines, "Foreground: " .. (colors.white or "N/A"))
          table.insert(lines, "Blue:       " .. (colors.blue or "N/A"))
          table.insert(lines, "Green:      " .. (colors.green or "N/A"))
          table.insert(lines, "Red:        " .. (colors.red or "N/A"))
          table.insert(lines, "Yellow:     " .. (colors.yellow or "N/A"))
          table.insert(lines, "Purple:     " .. (colors.purple or "N/A"))
          table.insert(lines, "Orange:     " .. (colors.orange or "N/A"))
        else
          table.insert(lines, "Could not load theme preview")
        end
        
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      end,
    }),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        
        if selection then
          switch_theme(selection.value)
        end
      end)
      
      -- Live preview on cursor move
      actions.move_selection_next:replace(function()
        actions.move_selection_next(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          -- Optional: Could add live preview here
        end
      end)
      
      actions.move_selection_previous:replace(function()
        actions.move_selection_previous(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          -- Optional: Could add live preview here
        end
      end)
      
      return true
    end,
  }):find()
end

-- Setup telescope extension
function M.setup()
  local telescope = require("telescope")
  
  -- Register the themes extension
  telescope.register_extension({
    exports = {
      themes = M.themes,
    },
  })
end

return M