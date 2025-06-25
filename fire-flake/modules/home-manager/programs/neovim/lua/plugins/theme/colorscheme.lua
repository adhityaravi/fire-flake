-- Enhanced Colorscheme utilities with NvChad Base46 integration and Telescope picker
local M = {}

-- Check if NvChad Base46 is available
local has_base46, base46 = pcall(require, "base46")

-- Simple NvChad theme picker (if base46 is available)
local function nvchad_theme_picker()
  if not has_base46 then
    vim.notify("NvChad Base46 not available", vim.log.levels.WARN)
    return
  end

  -- Get available themes by scanning the theme directory
  local theme_path = "/nix/store/7xg81hp0jk2kb295ys1n51bx9cr7dxp5-vimplugin-nvchad-base46-2.5/lua/base46/themes/"
  local themes = {}
  
  -- Read available themes from filesystem
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
  
  -- Fallback to known themes if directory read fails
  if #themes == 0 then
    themes = {
      "ayu_dark", "ayu_light", "bearded-arc", "catppuccin", "chocolate", "chadracula",
      "dark_horizon", "decay", "doomchad", "everblush", "everforest", "falcon",
      "github_dark", "github_light", "gruvbox", "gruvchad", "jabuti", "jellybeans",
      "kanagawa", "material-darker", "melange", "monochrome", "nightfox", "nightlamp",
      "nightowl", "nord", "oceanic-next", "onedark", "one_light", "onenord",
      "palenight", "rosepine", "rosepine_dawn", "solarized_dark", "solarized_light",
      "tokyodark", "tokyonight", "tomorrow_night", "vscode_dark", "yoru"
    }
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
      results = themes,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        if selection then
          -- Load the theme using NvChad's approach
          local ok, err = pcall(function()
            -- Update nvconfig theme (shared reference, so Base46 will see the change)
            local nvconfig = require("nvconfig")
            nvconfig.base46.theme = selection.value
            vim.g.nvchad_theme = selection.value
            
            -- Use NvChad's approach: just reload highlights
            local base46 = require("base46")
            base46.load_all_highlights()
            
            -- Refresh lualine with new theme colors
            pcall(function()
              if _G.get_nvchad_lualine_theme then
                require("lualine").setup({
                  options = { theme = _G.get_nvchad_lualine_theme() }
                })
              end
            end)
            
            vim.notify("✓ Loaded NvChad theme: " .. selection.value, vim.log.levels.INFO)
          end)
          
          if ok then
            M.save(selection.value, true)
            M.palette()
          else
            vim.notify("Failed to load NvChad theme: " .. selection.value .. " (" .. tostring(err) .. ")", vim.log.levels.ERROR)
          end
        end
        actions.close(prompt_bufnr)
      end)
      return true
    end,
  }):find()
end

-- location to persist the chosen theme
local config_path = vim.fn.stdpath("state") .. "/colorscheme"
local nvchad_config_path = vim.fn.stdpath("state") .. "/nvchad_theme"

local function write_theme(theme, is_nvchad)
  if theme and #theme > 0 then
    local path = is_nvchad and nvchad_config_path or config_path
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    vim.fn.writefile({ theme }, path)
  end
end

local function read_theme(is_nvchad)
  local path = is_nvchad and nvchad_config_path or config_path
  if vim.fn.filereadable(path) == 1 then
    local t = vim.fn.readfile(path)[1]
    if t and #t > 0 then
      return t
    end
  end
end

function M.save(theme, is_nvchad)
  write_theme(theme or vim.g.colors_name, is_nvchad)
end

function M.load()
  -- First try to load NvChad theme if available
  if has_base46 then
    local nvchad_theme = read_theme(true)
    if nvchad_theme then
      local ok, err = pcall(function()
        -- Update nvconfig theme (shared reference, so Base46 will see the change)
        local nvconfig = require("nvconfig")
        nvconfig.base46.theme = nvchad_theme
        vim.g.nvchad_theme = nvchad_theme
        
        -- Use NvChad's approach: just reload highlights
        local base46 = require("base46")
        base46.load_all_highlights()
        
        -- Refresh lualine with new theme colors
        pcall(function()
          if _G.get_nvchad_lualine_theme then
            require("lualine").setup({
              options = { theme = _G.get_nvchad_lualine_theme() }
            })
          end
        end)
      end)
      if ok then
        return
      end
    end
  end
  
  -- Fall back to regular colorschemes
  local theme = read_theme(false)
  if theme then
    local ok, err = pcall(vim.cmd.colorscheme, theme)
    if not ok then
      vim.notify("Failed to load colorscheme: " .. theme .. " (" .. err .. ")", vim.log.levels.ERROR)
    end
  end
end

-- automatically persist on colorscheme change
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    M.save(vim.g.colors_name, false)
  end,
})

-- automatically persist NvChad theme changes
vim.api.nvim_create_autocmd("User", {
  pattern = "Base46ThemeChange",
  callback = function()
    if vim.g.nvchad_theme then
      M.save(vim.g.nvchad_theme, true)
    end
  end,
})

-- simple floating palette showing some highlight groups
function M.palette(timeout)
  local groups = {
    "Normal",
    "Comment",
    "Constant",
    "String",
    "Identifier",
    "Statement",
    "PreProc",
    "Type",
    "Special",
  }

  local lines = groups

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  for i, grp in ipairs(groups) do
    vim.api.nvim_buf_add_highlight(buf, -1, grp, i - 1, 0, -1)
  end

  local width = 0
  for _, grp in ipairs(groups) do
    width = math.max(width, #grp)
  end
  width = math.max(20, width + 2)
  local height = #groups
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    row = 1,
    col = vim.o.columns - width - 2,
    style = "minimal",
    border = "rounded",
  })

  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, silent = true })

  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, timeout or 3000)
end

-- Enhanced theme picker with both NvChad and regular themes
function M.pick()
  -- Show a menu to choose between NvChad themes and regular themes
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local options = {}
  
  if has_base46 then
    table.insert(options, "🎨 NvChad Themes")
  end
  table.insert(options, "🌈 Regular Colorschemes")

  pickers.new({}, {
    prompt_title = "Theme Categories",
    finder = finders.new_table {
      results = options,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        
        if selection then
          if selection.value:find("NvChad") then
            -- Use NvChad theme picker
            nvchad_theme_picker()
          else
            -- Use regular colorscheme picker
            M.pick_regular()
          end
        end
      end)
      return true
    end,
  }):find()
end

-- Regular colorscheme picker (your original functionality)
function M.pick_regular()
  local actions = require("telescope.actions")
  local state = require("telescope.actions.state")

  require("telescope.builtin").colorscheme {
    enable_preview = true,
    attach_mappings = function(_, map)
      map("i", "<CR>", function(prompt_bufnr)
        local entry = state.get_selected_entry()
        if entry then
          local theme = entry.value
          actions.close(prompt_bufnr)
          local ok, err = pcall(vim.cmd.colorscheme, theme)
          if ok then
            M.palette()
          else
            vim.notify("Failed to load colorscheme: " .. theme .. " (" .. err .. ")", vim.log.levels.ERROR)
          end
        else
          vim.notify("No colorscheme selected", vim.log.levels.WARN)
        end
      end)
      return true
    end,
  }
end

-- Direct NvChad theme picker access
function M.pick_nvchad()
  nvchad_theme_picker()
end

return M

