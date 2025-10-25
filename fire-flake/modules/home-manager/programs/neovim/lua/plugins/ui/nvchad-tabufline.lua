-- NvChad Tabufline (Buffer management) with preserved custom features
-- This replaces bufferline while maintaining diagnostics and git integration

local M = {}
local devicons = require "nvim-web-devicons"
local fn = vim.fn

-- Buffer management functions
M.bufilter = function()
  local bufs = vim.t.bufs or {}

  for i = #bufs, 1, -1 do
    if not vim.api.nvim_buf_is_valid(bufs[i]) then
      table.remove(bufs, i)
    end
  end

  vim.t.bufs = bufs
  return bufs
end

M.tabuflineNext = function()
  local bufs = M.bufilter() or {}

  for i, v in ipairs(bufs) do
    if vim.api.nvim_get_current_buf() == v then
      vim.cmd(i == #bufs and "b" .. bufs[1] or "b" .. bufs[i + 1])
      break
    end
  end
end

M.tabuflinePrev = function()
  local bufs = M.bufilter() or {}

  for i, v in ipairs(bufs) do
    if vim.api.nvim_get_current_buf() == v then
      vim.cmd(i == 1 and "b" .. bufs[#bufs] or "b" .. bufs[i - 1])
      break
    end
  end
end

M.close_buffer = function(bufnr)
  if vim.bo.buftype == "terminal" then
    vim.cmd(vim.bo.buflisted and "set nobl | enew" or "hide")
  else
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    vim.cmd("confirm bd" .. bufnr)
  end
end

-- Your preserved diagnostics indicator logic
local function get_diagnostics_count(bufnr)
  local diagnostics = vim.diagnostic.get(bufnr)
  local count = { error = 0, warn = 0, info = 0, hint = 0 }
  
  for _, diagnostic in ipairs(diagnostics) do
    if diagnostic.severity == vim.diagnostic.severity.ERROR then
      count.error = count.error + 1
    elseif diagnostic.severity == vim.diagnostic.severity.WARN then
      count.warn = count.warn + 1
    elseif diagnostic.severity == vim.diagnostic.severity.INFO then
      count.info = count.info + 1
    elseif diagnostic.severity == vim.diagnostic.severity.HINT then
      count.hint = count.hint + 1
    end
  end
  
  return count
end

local function get_diagnostics_indicator(bufnr)
  local count = get_diagnostics_count(bufnr)
  local result = ""
  
  if count.error > 0 then
    result = result .. " " .. count.error
  end
  if count.warn > 0 then
    result = result .. " " .. count.warn
  end
  
  return result
end

-- Git integration (preserved from your bufferline config)
local function get_git_branch()
  -- Try to get git branch from various sources
  local branch = vim.b.gitsigns_head or fn.FugitiveHead() or ""
  return branch ~= "" and " " .. branch or ""
end

-- Buffer component with your preserved features
M.bufferlist = function()
  local buffers = M.bufilter()
  local current_buf = vim.api.nvim_get_current_buf()
  local result = {}

  -- Add offset for file explorer (preserved feature)
  local nvim_tree_width = 0
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "NvimTree" then
      nvim_tree_width = vim.api.nvim_win_get_width(win)
      table.insert(result, "%#NvimTreeWinSeparator#" .. string.rep(" ", nvim_tree_width))
      break
    end
  end

  for i, bufnr in ipairs(buffers) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local filename = fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
      if filename == "" then
        filename = "No Name"
      end

      local icon, icon_highlight = devicons.get_icon(filename, nil, { default = true })
      icon = icon or ""

      local is_current = (bufnr == current_buf)
      local modified = vim.bo[bufnr].modified

      -- Get diagnostics for this buffer
      local diag_indicator = get_diagnostics_indicator(bufnr)
      
      -- Choose highlight group based on buffer state
      local hl_group
      if is_current then
        hl_group = "%#TbBufOn#"
      else
        hl_group = "%#TbBufOff#"
      end

      -- Build buffer display
      local buffer_display = hl_group .. " "
      
      -- Add icon with color
      if icon ~= "" then
        buffer_display = buffer_display .. "%#" .. (icon_highlight or "TbBufOn") .. "#" .. icon .. " "
      end
      
      -- Add filename
      buffer_display = buffer_display .. hl_group .. filename
      
      -- Add modified indicator
      if modified then
        buffer_display = buffer_display .. " ●"
      end
      
      -- Add diagnostics
      if diag_indicator ~= "" then
        buffer_display = buffer_display .. "%#DiagnosticError#" .. diag_indicator
      end
      
      buffer_display = buffer_display .. " "

      -- Add close button for current buffer
      if is_current then
        buffer_display = buffer_display .. "%#TbBufOnClose# 󰅖 "
      end

      table.insert(result, buffer_display)
    end
  end

  return table.concat(result)
end

-- Right side with git branch (preserved feature)
M.tabufline_right = function()
  local git_branch = get_git_branch()
  if git_branch ~= "" then
    return "%#TbBufOffModified#" .. git_branch .. " "
  end
  return ""
end

-- Main tabufline function
M.run = function()
  return M.bufferlist() .. "%=" .. M.tabufline_right()
end

-- Set up the tabufline
vim.opt.tabline = "%!v:lua.require('plugins.ui.nvchad-tabufline').run()"

-- Preserved keymaps with NvChad functions
vim.keymap.set("n", "<S-l>", function() M.tabuflineNext() end, { desc = "Next buffer" })
vim.keymap.set("n", "<S-h>", function() M.tabuflinePrev() end, { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>bd", function() M.close_buffer() end, { desc = "Close buffer" })

-- Buffer movement functions (adapted from your config)
local function move_buffer_right()
  local bufs = M.bufilter()
  local current_buf = vim.api.nvim_get_current_buf()
  
  for i, v in ipairs(bufs) do
    if current_buf == v then
      if i < #bufs then
        bufs[i], bufs[i + 1] = bufs[i + 1], bufs[i]
      end
      break
    end
  end
  vim.t.bufs = bufs
end

local function move_buffer_left()
  local bufs = M.bufilter()
  local current_buf = vim.api.nvim_get_current_buf()
  
  for i, v in ipairs(bufs) do
    if current_buf == v then
      if i > 1 then
        bufs[i], bufs[i - 1] = bufs[i - 1], bufs[i]
      end
      break
    end
  end
  vim.t.bufs = bufs
end

-- Buffer picking function
local function pick_buffer()
  local bufs = M.bufilter()
  if #bufs <= 1 then
    return
  end
  
  -- Simple buffer picker using vim.ui.select
  local buffer_names = {}
  for i, bufnr in ipairs(bufs) do
    local name = fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
    if name == "" then name = "No Name" end
    table.insert(buffer_names, string.format("%d: %s", i, name))
  end
  
  vim.ui.select(buffer_names, {
    prompt = "Pick buffer:",
  }, function(choice, idx)
    if choice and idx then
      vim.cmd("b" .. bufs[idx])
    end
  end)
end

local function close_other_buffers()
  local current_buf = vim.api.nvim_get_current_buf()
  local bufs = M.bufilter()
  
  for _, bufnr in ipairs(bufs) do
    if bufnr ~= current_buf then
      vim.cmd("bd " .. bufnr)
    end
  end
end

-- Additional preserved keymaps
vim.keymap.set("n", "<leader>bp", pick_buffer, { desc = "Pick buffer" })
vim.keymap.set("n", "<leader>bo", close_other_buffers, { desc = "Close others" })
vim.keymap.set("n", "<leader>bl", move_buffer_right, { desc = "Move buffer right" })
vim.keymap.set("n", "<leader>bh", move_buffer_left, { desc = "Move buffer left" })

-- Auto-update buffer list
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead", "TabEnter", "TermOpen" }, {
  callback = function(args)
    if vim.t.bufs == nil then
      vim.t.bufs = {}
    end

    local bufs = vim.t.bufs

    -- check for duplicates
    if not vim.tbl_contains(bufs, args.buf) and vim.bo[args.buf].buflisted then
      table.insert(bufs, args.buf)
      vim.t.bufs = bufs
    end
  end,
})

vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(args)
    local bufs = vim.t.bufs

    for i, v in ipairs(bufs) do
      if v == args.buf then
        table.remove(bufs, i)
        vim.t.bufs = bufs
        break
      end
    end
  end,
})

-- Define highlight groups to match NvChad theme
local function setup_tabufline_highlights()
  local colors = require("base46").get_theme_tb "base_30"
  
  vim.api.nvim_set_hl(0, "TbBufOn", { fg = colors.white, bg = colors.black })
  vim.api.nvim_set_hl(0, "TbBufOff", { fg = colors.grey_fg, bg = colors.one_bg })
  vim.api.nvim_set_hl(0, "TbBufOnClose", { fg = colors.red, bg = colors.black })
  vim.api.nvim_set_hl(0, "TbBufOffModified", { fg = colors.blue, bg = colors.one_bg })
end

-- Set up highlights when colorscheme changes
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = setup_tabufline_highlights,
})

-- Set up highlights on load
vim.api.nvim_create_autocmd("VimEnter", {
  callback = setup_tabufline_highlights,
})

return M