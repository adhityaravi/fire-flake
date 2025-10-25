local M = {}
local fn = vim.fn

-- Get base46 path dynamically from the installed plugin
local function get_base46_path()
  local has_base46, base46 = pcall(require, "base46")
  if not has_base46 then
    return nil
  end
  
  -- Get the base46 module info to find its path
  local base46_info = debug.getinfo(base46.load_all_highlights, "S")
  if base46_info and base46_info.source then
    local source_path = base46_info.source:sub(2) -- remove @ prefix
    return vim.fn.fnamemodify(source_path, ":p:h")
  end
  
  return nil
end

M.list_themes = function()
  local base46_path = get_base46_path()
  
  if not base46_path then
    -- Fallback: Use the known Nix store path
    local nix_path = "/nix/store/7xg81hp0jk2kb295ys1n51bx9cr7dxp5-vimplugin-nvchad-base46-2.5/lua/base46"
    if vim.fn.isdirectory(nix_path .. "/themes") == 1 then
      base46_path = nix_path
    end
  end
  
  local default_themes = {}
  
  if base46_path then
    local themes_dir = base46_path .. '/themes'
    if vim.fn.isdirectory(themes_dir) == 1 then
      default_themes = vim.fn.readdir(themes_dir)
    end
  end
  
  -- Fallback to hardcoded list if directory reading fails
  if #default_themes == 0 then
    default_themes = {
      "ayu_dark.lua", "ayu_light.lua", "bearded-arc.lua", "catppuccin.lua", 
      "chocolate.lua", "chadracula.lua", "dark_horizon.lua", "decay.lua", 
      "doomchad.lua", "everblush.lua", "everforest.lua", "falcon.lua",
      "github_dark.lua", "github_light.lua", "gruvbox.lua", "gruvchad.lua", 
      "jabuti.lua", "jellybeans.lua", "kanagawa.lua", "material-darker.lua", 
      "melange.lua", "monochrome.lua", "nightfox.lua", "nightlamp.lua",
      "nightowl.lua", "nord.lua", "oceanic-next.lua", "onedark.lua", 
      "one_light.lua", "onenord.lua", "palenight.lua", "rosepine.lua", 
      "rosepine_dawn.lua", "solarized_dark.lua", "solarized_light.lua",
      "tokyodark.lua", "tokyonight.lua", "tomorrow_night.lua", 
      "vscode_dark.lua", "yoru.lua"
    }
  end

  -- Check for custom themes in user config
  local custom_themes = vim.uv.fs_stat(fn.stdpath "config" .. "/lua/themes")
  if custom_themes and custom_themes.type == "directory" then
    local themes_tb = fn.readdir(fn.stdpath "config" .. "/lua/themes")
    for _, value in ipairs(themes_tb) do
      table.insert(default_themes, value)
    end
  end

  -- Remove .lua extension from theme names
  for index, theme in ipairs(default_themes) do
    default_themes[index] = theme:match "(.+)%..+" or theme
  end

  return default_themes
end

M.replace_word = function(old, new, filepath)
  -- In our setup, we don't modify chadrc.lua files directly
  -- Instead, we update the runtime configuration and save preference
  local theme_name = new:gsub('"', '')
  
  -- Update nvconfig
  local nvconfig = require("nvconfig")
  nvconfig.base46.theme = theme_name
  
  -- Update chadrc
  local chadrc = require("chadrc")
  chadrc.base46.theme = theme_name
  
  -- Save theme preference to state file
  local theme_path = vim.fn.stdpath("state") .. "/nvchad_theme"
  vim.fn.mkdir(vim.fn.fnamemodify(theme_path, ":h"), "p")
  vim.fn.writefile({ theme_name }, theme_path)
  
  print("Updated theme to: " .. theme_name)
end

-- Utility function for setting clean buffer options (used by UI components)
M.set_cleanbuf_opts = function(ft, buf)
  local opt_local = vim.api.nvim_set_option_value
  opt_local("buflisted", false, { buf = buf })
  opt_local("modifiable", false, { buf = buf })
  opt_local("buftype", "nofile", { buf = buf })
  opt_local("number", false, { scope = "local" })
  opt_local("list", false, { scope = "local" })
  opt_local("wrap", false, { scope = "local" })
  opt_local("relativenumber", false, { scope = "local" })
  opt_local("cursorline", false, { scope = "local" })
  opt_local("colorcolumn", "0", { scope = "local" })
  opt_local("foldcolumn", "0", { scope = "local" })
  if ft and buf then
    opt_local("ft", ft, { buf = buf })
    vim.g[ft .. "_displayed"] = true
  end
end

-- Reload modules (simplified for our environment)
M.reload = function(module)
  if module then
    pcall(require("plenary.reload").reload_module, module)
  end
  
  pcall(require("plenary.reload").reload_module, "nvconfig")
  pcall(require("plenary.reload").reload_module, "chadrc")
  pcall(require("plenary.reload").reload_module, "base46")
  
  -- Reload highlights
  local has_base46, base46 = pcall(require, "base46")
  if has_base46 then
    base46.load_all_highlights()
  end
end

return M