-- #todo: refactor status functions to be more generic
-- get copilot status
local function copilot_status()
  local ok, client = pcall(require, "copilot.client")
  if not ok or type(client) ~= "table" then
    return ""
  end

  local buf = vim.api.nvim_get_current_buf()
  -- skip invalid buffers or no filetype
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype == "" then
    return ""
  end

  -- Get attached LSP clients for this buffer
  -- Not as simple as auto-save, since there is auth involved
  local clients = vim.lsp.get_clients({ bufnr = buf })
  for _, client in ipairs(clients) do
    if client and client.name == "copilot" then
      return "COP"
    end
  end

  return ""
end

-- get autosave status
local function autosave_status()
  local ok, auto_save = pcall(require, "auto-save")
  if not ok or type(auto_save) ~= "table" then
    return ""
  end

  local buf = vim.api.nvim_get_current_buf()
  local buftype = vim.bo[buf].buftype
  local filetype = vim.bo[buf].filetype
  -- skip special buffers
  local invalid_types = { "nofile", "prompt", "quickfix", "terminal" }
  if vim.tbl_contains(invalid_types, buftype) or filetype == "" then
    return ""
  end

  if vim.g.auto_save_enabled then
    return "AUT"
  else
    return ""
  end
end

-- get lsp status
local function lsp_status()
  local clients = vim.lsp.get_clients({ bufnr = 0 })

  local lsp_clients = vim.tbl_filter(function(client)
    return client.name ~= "copilot"
  end, clients)

  if vim.tbl_isempty(lsp_clients) then
    return "  No LSP"
  end

  local names = {}
  for _, client in ipairs(lsp_clients) do
    table.insert(names, client.name)
  end

  return "  " .. table.concat(names, ", ")
end


-- lualine
-- Function to get NvChad Base46 colors for lualine theme
local function get_nvchad_lualine_theme()
  local has_base46, base46 = pcall(require, "base46")
  if not has_base46 then
    return "auto"
  end
  
  -- Try to get Base46 colors
  local ok, colors = pcall(function()
    return base46.get_theme_tb("base_30")
  end)
  
  if not ok or not colors then
    return "auto"
  end
  
  -- Create lualine theme using Base46 colors
  local nvchad_theme = {
    normal = {
      a = { bg = colors.blue, fg = colors.black },
      b = { bg = colors.one_bg, fg = colors.light_grey },
      c = { bg = colors.one_bg2, fg = colors.white },
    },
    insert = {
      a = { bg = colors.green, fg = colors.black },
      b = { bg = colors.one_bg, fg = colors.light_grey },
    },
    visual = {
      a = { bg = colors.purple, fg = colors.black },
      b = { bg = colors.one_bg, fg = colors.light_grey },
    },
    replace = {
      a = { bg = colors.red, fg = colors.black },
      b = { bg = colors.one_bg, fg = colors.light_grey },
    },
    command = {
      a = { bg = colors.yellow, fg = colors.black },
      b = { bg = colors.one_bg, fg = colors.light_grey },
    },
    inactive = {
      a = { bg = colors.one_bg, fg = colors.light_grey },
      b = { bg = colors.one_bg, fg = colors.light_grey },
      c = { bg = colors.one_bg, fg = colors.light_grey },
    },
  }
  
  return nvchad_theme
end

-- Export the theme function for external use
_G.get_nvchad_lualine_theme = get_nvchad_lualine_theme

require("lualine").setup({
    options = {
      theme = get_nvchad_lualine_theme(),
      icons_enabled = true,
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
      always_divide_middle = true,
      globalstatus = true,
    },

    sections = {
      lualine_a = { "mode" },

      lualine_b = {
        "branch",
        "diff",
      },

      lualine_c = {
        {
          copilot_status,
          icon = "",
          color = { fg = "#00FF00" },
          cond = function()
            return copilot_status() ~= ""
          end,
        },
        {
          autosave_status,
          icon = "",
          color = { fg = "#00FF00" },
          cond = function()
            return autosave_status() ~= ""
          end,
        },
      },

      lualine_x = {
        lsp_status,
        "encoding",
        "fileformat",
        "filetype",
      },

      lualine_y = { "progress" },

      lualine_z = {
        function()
          local mode = vim.fn.mode()
          if mode == "n" then
            return "≽^•⩊•^≼"
          elseif mode == "i" then
            return "ฅ^•ﻌ•^ฅ"
          else
            return "(=ↀωↀ=)"
          end
        end
      },
    },

    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {},
      lualine_x = { "location" },
      lualine_y = {},
      lualine_z = {},
    },
  })

