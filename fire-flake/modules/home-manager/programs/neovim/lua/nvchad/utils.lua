-- Simple NvChad utils for theme persistence
local M = {}

-- Simple function to replace theme in chadrc.lua
-- This is a minimal implementation that just updates our nvconfig
function M.replace_word(old_word, new_word)
  -- Extract theme name from the new_word (remove quotes)
  local theme_name = new_word:gsub('"', '')
  
  -- Update our global nvconfig
  local nvconfig = require("nvconfig")
  nvconfig.base46.theme = theme_name
  nvconfig.ui.theme = theme_name
  
  -- Save the theme preference
  local colorscheme_mod = require("plugins.theme.colorscheme")
  colorscheme_mod.save(theme_name, true)
  
  print("Updated theme to: " .. theme_name)
end

return M