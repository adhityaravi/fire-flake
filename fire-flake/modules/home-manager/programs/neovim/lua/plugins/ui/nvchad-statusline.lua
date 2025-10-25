-- NvChad Statusline with preserved custom features
-- This replaces lualine while maintaining all your custom indicators and cute mode displays

local M = {}

-- Import NvChad statusline components
local stbufnr = function()
  return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

-- Your custom status functions (preserved from lualine.lua)
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
  local clients = vim.lsp.get_clients({ bufnr = buf })
  for _, client in ipairs(clients) do
    if client and client.name == "copilot" then
      return "COP"
    end
  end

  return ""
end

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

local function lsp_status()
  local clients = vim.lsp.get_clients({ bufnr = stbufnr() })

  local lsp_clients = vim.tbl_filter(function(client)
    return client.name ~= "copilot"
  end, clients)

  if vim.tbl_isempty(lsp_clients) then
    return "  No LSP"
  end

  local names = {}
  for _, client in ipairs(lsp_clients) do
    table.insert(names, client.name)
  end

  return "  " .. table.concat(names, ", ")
end

-- Your custom cute mode indicators (preserved)
local function cute_mode()
  local mode = vim.fn.mode()
  if mode == "n" then
    return "≽^•⩊•^≼"
  elseif mode == "i" then
    return "ฅ^•ﻌ•^ฅ"
  else
    return "(=ↀωↀ=)"
  end
end

-- NvChad statusline components with your customizations
M.mode = function()
  if not vim.api.nvim_get_option_value("buflisted", { buf = stbufnr() }) then
    return ""
  end

  local modes = {
    ["n"] = { "NORMAL", "St_NormalMode" },
    ["no"] = { "NORMAL (no)", "St_NormalMode" },
    ["nov"] = { "NORMAL (nov)", "St_NormalMode" },
    ["noV"] = { "NORMAL (noV)", "St_NormalMode" },
    ["noCTRL-V"] = { "NORMAL", "St_NormalMode" },
    ["niI"] = { "NORMAL i", "St_NormalMode" },
    ["niR"] = { "NORMAL r", "St_NormalMode" },
    ["niV"] = { "NORMAL v", "St_NormalMode" },
    ["nt"] = { "NTERMINAL", "St_NTerminalMode" },
    ["ntT"] = { "NTERMINAL (ntT)", "St_NTerminalMode" },

    ["v"] = { "VISUAL", "St_VisualMode" },
    ["vs"] = { "V-CHAR (Ctrl O)", "St_VisualMode" },
    ["V"] = { "V-LINE", "St_VisualMode" },
    ["Vs"] = { "V-LINE", "St_VisualMode" },
    [""] = { "V-BLOCK", "St_VisualMode" },

    ["i"] = { "INSERT", "St_InsertMode" },
    ["ic"] = { "INSERT (completion)", "St_InsertMode" },
    ["ix"] = { "INSERT completion", "St_InsertMode" },

    ["t"] = { "TERMINAL", "St_TerminalMode" },

    ["R"] = { "REPLACE", "St_ReplaceMode" },
    ["Rc"] = { "REPLACE (Rc)", "St_ReplaceMode" },
    ["Rx"] = { "REPLACEa (Rx)", "St_ReplaceMode" },
    ["Rv"] = { "V-REPLACE", "St_ReplaceMode" },
    ["Rvc"] = { "V-REPLACE (Rvc)", "St_ReplaceMode" },
    ["Rvx"] = { "V-REPLACE (Rvx)", "St_ReplaceMode" },

    ["s"] = { "SELECT", "St_SelectMode" },
    ["S"] = { "S-LINE", "St_SelectMode" },
    [""] = { "S-BLOCK", "St_SelectMode" },
    ["c"] = { "COMMAND", "St_CommandMode" },
    ["cv"] = { "COMMAND", "St_CommandMode" },
    ["ce"] = { "COMMAND", "St_CommandMode" },
    ["r"] = { "PROMPT", "St_ConfirmMode" },
    ["rm"] = { "MORE", "St_ConfirmMode" },
    ["r?"] = { "CONFIRM", "St_ConfirmMode" },
    ["!"] = { "SHELL", "St_TerminalMode" },
  }

  local m = vim.api.nvim_get_mode().mode
  local current_mode = "%#" .. modes[m][2] .. "#" .. " " .. modes[m][1]
  local mode_sep1 = "%#" .. modes[m][2] .. "Sep" .. "#" .. ""

  return current_mode .. mode_sep1 .. "%#ST_EmptySpace#" .. " "
end

-- File info component
M.fileInfo = function()
  local icon = " 󰈚 "
  local filename = (vim.fn.expand "%" == "" and "Empty ") or vim.fn.expand "%:t"

  if filename ~= "Empty " then
    local devicons_present, devicons = pcall(require, "nvim-web-devicons")

    if devicons_present then
      local ft_icon = devicons.get_icon(filename)
      icon = (ft_icon ~= nil and " " .. ft_icon) or ""
    end

    filename = " " .. filename .. " "
  end

  return "%#St_file_info#" .. icon .. filename .. "%#St_file_sep#" .. ""
end

-- Git component
M.git = function()
  if not vim.b[stbufnr()].gitsigns_head or vim.b[stbufnr()].gitsigns_git_status then
    return ""
  end

  local git_status = vim.b[stbufnr()].gitsigns_status_dict

  local added = (git_status.added and git_status.added ~= 0) and ("  " .. git_status.added) or ""
  local changed = (git_status.changed and git_status.changed ~= 0) and ("  " .. git_status.changed) or ""
  local removed = (git_status.removed and git_status.removed ~= 0) and ("  " .. git_status.removed) or ""
  local branch_name = " " .. git_status.head

  return "%#St_gitIcons#" .. branch_name .. added .. changed .. removed
end

-- Your custom indicators integrated into NvChad style
M.copilot = function()
  local status = copilot_status()
  if status ~= "" then
    return "%#St_copilot#" .. " " .. status .. " "
  end
  return ""
end

M.autosave = function()
  local status = autosave_status()
  if status ~= "" then
    return "%#St_autosave#" .. " " .. status .. " "
  end
  return ""
end

-- LSP component (NvChad style)
M.lsp = function()
  return "%#St_Lsp#" .. lsp_status()
end

-- Position component
M.cursor_position = function()
  return "%#St_pos_sep#" .. "" .. "%#St_pos_icon#" .. " %l:%c " .. "%#St_pos_text#" .. " %p%% "
end

-- Your cute mode indicator (placed at the end)
M.cute_mode = function()
  return "%#St_cute_mode#" .. " " .. cute_mode() .. " "
end

-- Encoding and filetype
M.file_encoding = function()
  local encode = vim.bo[stbufnr()].fenc ~= "" and vim.bo[stbufnr()].fenc or vim.o.enc
  return " " .. encode:upper() .. " "
end

-- Main statusline function
M.run = function()
  local modules = {
    M.mode(),
    M.fileInfo(),
    M.git(),

    "%=", -- Center alignment

    M.copilot(),
    M.autosave(),

    "%=", -- Right alignment

    M.lsp(),
    "%#St_file_sep#" .. "",
    M.file_encoding(),
    M.cursor_position(),
    M.cute_mode(),
  }

  return table.concat(modules)
end

-- Set up the statusline
vim.opt.statusline = "%!v:lua.require('plugins.ui.nvchad-statusline').run()"

-- Define highlight groups to match NvChad theme
local function setup_highlights()
  local colors = require("base46").get_theme_tb "base_30"
  
  vim.api.nvim_set_hl(0, "St_copilot", { fg = colors.green, bg = colors.one_bg })
  vim.api.nvim_set_hl(0, "St_autosave", { fg = colors.blue, bg = colors.one_bg })
  vim.api.nvim_set_hl(0, "St_cute_mode", { fg = colors.pink, bg = colors.statusline_bg, bold = true })
end

-- Set up highlights when colorscheme changes
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = setup_highlights,
})

-- Set up highlights on load
vim.api.nvim_create_autocmd("VimEnter", {
  callback = setup_highlights,
})

return M