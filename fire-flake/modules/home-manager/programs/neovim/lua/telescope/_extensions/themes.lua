-- Override NvChad's telescope themes extension with our working version
-- This provides the same visual experience but uses our persistence mechanism

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local previewers = require "telescope.previewers"

local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

-- Function to reload theme using our system
local function reload_theme(name)
  local nvconfig = require("nvconfig")
  nvconfig.base46.theme = name
  nvconfig.ui.theme = name
  
  require("base46").load_all_highlights()
  
  -- Update lualine
  pcall(function()
    if _G.get_nvchad_lualine_theme then
      require("lualine").setup({
        options = { theme = _G.get_nvchad_lualine_theme() }
      })
    end
  end)
  
  -- Save theme preference
  local colorscheme_mod = require("plugins.theme.colorscheme")
  colorscheme_mod.save(name, true)
  
  vim.api.nvim_exec_autocmds("User", { pattern = "NvChadThemeReload" })
end

-- Get list of available themes
local function get_themes()
  local themes = {}
  
  -- Get themes from Base46 directory
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
  
  -- Sort themes
  table.sort(themes)
  
  return themes
end

-- Main switcher function with live preview
local function switcher()
  local bufnr = vim.api.nvim_get_current_buf()
  local themes = get_themes()
  local current_theme = require("nvconfig").base46.theme

  -- Create previewer that shows current buffer with applied theme
  local previewer = previewers.new_buffer_previewer {
    title = "Theme Preview",
    define_preview = function(self, entry)
      -- Copy current buffer content
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

      -- Apply syntax highlighting
      local ft = (vim.filetype.match { buf = bufnr } or "diff"):match "%w+"
      require("telescope.previewers.utils").highlighter(self.state.bufnr, ft)
      
      -- Apply the theme to see live preview
      if entry and entry.value then
        reload_theme(entry.value)
      end
    end,
  }

  pickers.new({}, {
    prompt_title = "NvChad Themes",
    finder = finders.new_table {
      results = themes,
      entry_maker = function(theme)
        return {
          value = theme,
          display = theme == current_theme and theme .. " (current)" or theme,
          ordinal = theme,
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    previewer = previewer,
    attach_mappings = function(prompt_bufnr)
      -- Live preview on cursor movement
      local function update_preview()
        local selection = action_state.get_selected_entry()
        if selection then
          reload_theme(selection.value)
        end
      end

      -- Override default actions for live preview
      actions.move_selection_next:replace(function()
        actions.move_selection_next(prompt_bufnr)
        update_preview()
      end)

      actions.move_selection_previous:replace(function()
        actions.move_selection_previous(prompt_bufnr)
        update_preview()
      end)

      -- Save theme on enter
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        
        if selection then
          reload_theme(selection.value)
          vim.notify("✓ Applied NvChad theme: " .. selection.value, vim.log.levels.INFO)
        end
      end)

      return true
    end,
  }):find()
end

-- Register the extension
return require("telescope").register_extension {
  exports = {
    themes = switcher,
  },
}