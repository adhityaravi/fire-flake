-- NvChad Dashboard with preserved fire-flake branding and functionality
-- This replaces alpha while maintaining your custom ASCII art and buttons

local M = {}

-- Your preserved fire-flake ASCII art
M.header = {
  "                                   ",
  "                                   ",
  "                                   ",
  "   ⣴⣶⣤⡤⠦⣤⣀⣤⠆     ⣈⣭⣿⣶⣿⣦⣼⣆          ",
  "    ⠉⠻⢿⣿⠿⣿⣿⣶⣦⠤⠄⡠⢾⣿⣿⡿⠋⠉⠉⠻⣿⣿⡛⣦       ",
  "          ⠈⢿⣿⣟⠦ ⣾⣿⣿⣷    ⠻⠿⢿⣿⣧⣄     ",
  "           ⣸⣿⣿⢧ ⢻⠻⣿⣿⣷⣄⣀⠄⠢⣀⡀⠈⠙⠿⠄    ",
  "          ⢠⣿⣿⣿⠈    ⣻⣿⣿⣿⣿⣿⣿⣿⣛⣳⣤⣀⣀   ",
  "   ⢠⣧⣶⣥⡤⢄ ⣸⣿⣿⠘  ⢀⣴⣿⣿⡿⠛⣿⣿⣧⠈⢿⠿⠟⠛⠻⠿⠄  ",
  "  ⣰⣿⣿⠛⠻⣿⣿⡦⢹⣿⣷   ⢊⣿⣿⡏  ⢸⣿⣿⡇ ⢀⣠⣄⣾⠄   ",
  " ⣠⣿⠿⠛ ⢀⣿⣿⣷⠘⢿⣿⣦⡀ ⢸⢿⣿⣿⣄ ⣸⣿⣿⡇⣪⣿⡿⠿⣿⣷⡄  ",
  " ⠙⠃   ⣼⣿⡟  ⠈⠻⣿⣿⣦⣌⡇⠻⣿⣿⣷⣿⣿⣿ ⣿⣿⡇ ⠛⠻⢷⣄ ",
  "      ⢻⣿⣿⣄   ⠈⠻⣿⣿⣿⣷⣿⣿⣿⣿⣿⡟ ⠫⢿⣿⡆     ",
  "       ⠻⣿⣿⣿⣿⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⡟⢀⣀⣤⣾⡿⠃     ",
  "                                   ",
  "                                   ",
  "     powered by fire-flake 🔥      ",
  "                                   ",
  "                                   ",
  "                                   ",
}

-- Your preserved buttons with NvChad styling
M.buttons = {
  { txt = "  New file", cmd = "ene | startinsert", keys = "e" },
  { txt = "󰈞  Find file", cmd = "Telescope find_files", keys = "f" },
  { txt = "  Browse files", cmd = "Telescope file_browser", keys = "d" },
  { txt = "  Projects", cmd = "Telescope project", keys = "p" },
  { txt = "󰄉  Restore session", cmd = "lua require('persistence').load()", keys = "s" },
  { txt = "  Lazy Git", cmd = "LazyGit", keys = "g" },
  { txt = "  Quit", cmd = "qa", keys = "q" },
}

-- Footer with version info (preserved)
M.get_footer = function()
  local v = vim.version()
  return {
    " ",
    " ",
    " ",
    " ",
    " ",
    " ",
    string.format("⚙  Neovim v%d.%d.%d  |  %s", v.major, v.minor, v.patch, os.date("%A, %d %B %Y")),
    " ",
  }
end

-- NvChad dashboard rendering
M.render = function()
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_get_current_win()
  
  vim.api.nvim_buf_set_option(buf, "filetype", "nvdash")
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "buflisted", false)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "readonly", true)

  local win_height = vim.api.nvim_win_get_height(win)
  local win_width = vim.api.nvim_win_get_width(win)

  -- Calculate positioning
  local header_height = #M.header
  local buttons_height = #M.buttons + 2  -- +2 for spacing
  local footer_height = #M.get_footer()
  local total_height = header_height + buttons_height + footer_height + 4  -- +4 for extra spacing

  local start_row = math.max(0, math.floor((win_height - total_height) / 2))
  local lines = {}

  -- Add empty lines for vertical centering
  for _ = 1, start_row do
    table.insert(lines, "")
  end

  -- Add header
  for _, line in ipairs(M.header) do
    local padding = math.max(0, math.floor((win_width - vim.fn.strdisplaywidth(line)) / 2))
    table.insert(lines, string.rep(" ", padding) .. line)
  end

  -- Add spacing
  table.insert(lines, "")
  table.insert(lines, "")

  -- Add buttons
  for i, button in ipairs(M.buttons) do
    local button_text = button.keys and string.format("  %s  %s", button.keys, button.txt) or button.txt
    local padding = math.max(0, math.floor((win_width - vim.fn.strdisplaywidth(button_text)) / 2))
    table.insert(lines, string.rep(" ", padding) .. button_text)
  end

  -- Add spacing
  table.insert(lines, "")
  table.insert(lines, "")

  -- Add footer
  for _, line in ipairs(M.get_footer()) do
    local padding = math.max(0, math.floor((win_width - vim.fn.strdisplaywidth(line)) / 2))
    table.insert(lines, string.rep(" ", padding) .. line)
  end

  -- Set buffer content
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- Set buffer in window
  vim.api.nvim_win_set_buf(win, buf)

  -- Set up keymaps for buttons
  for _, button in ipairs(M.buttons) do
    if button.keys then
      vim.keymap.set("n", button.keys, function()
        vim.cmd(button.cmd)
      end, { buffer = buf, silent = true })
    end
  end

  -- Set up highlights
  M.setup_highlights()
  M.apply_highlights(buf, lines, start_row)

  -- Auto-close on buffer enter
  vim.keymap.set("n", "<CR>", "<Nop>", { buffer = buf })
  vim.keymap.set("n", "q", "<cmd>bd<CR>", { buffer = buf, silent = true })

  -- Hide cursor and disable various UI elements
  vim.api.nvim_win_set_option(win, "cursorline", false)
  vim.api.nvim_win_set_option(win, "number", false)
  vim.api.nvim_win_set_option(win, "relativenumber", false)
  vim.api.nvim_win_set_option(win, "foldcolumn", "0")
  vim.api.nvim_win_set_option(win, "signcolumn", "no")
  
  vim.opt_local.showmode = false
  vim.opt_local.ruler = false
  vim.opt_local.laststatus = 0
  vim.opt_local.showtabline = 0
end

-- Set up highlight groups
M.setup_highlights = function()
  local colors = require("base46").get_theme_tb "base_30"
  
  vim.api.nvim_set_hl(0, "NvDashAscii", { fg = colors.blue, bold = true })
  vim.api.nvim_set_hl(0, "NvDashButtons", { fg = colors.light_grey })
  vim.api.nvim_set_hl(0, "NvDashFooter", { fg = colors.grey_fg })
  vim.api.nvim_set_hl(0, "NvDashBranding", { fg = colors.red, bold = true })
end

-- Apply highlights to specific lines
M.apply_highlights = function(buf, lines, start_row)
  local ns_id = vim.api.nvim_create_namespace("nvdash")
  
  -- Highlight ASCII art (lines 3-16 of header)
  for i = start_row + 4, start_row + 16 do
    if lines[i] then
      vim.api.nvim_buf_add_highlight(buf, ns_id, "NvDashAscii", i - 1, 0, -1)
    end
  end
  
  -- Highlight fire-flake branding
  for i, line in ipairs(lines) do
    if line:find("powered by fire%-flake") then
      vim.api.nvim_buf_add_highlight(buf, ns_id, "NvDashBranding", i - 1, 0, -1)
      break
    end
  end
  
  -- Highlight buttons
  for i, line in ipairs(lines) do
    if line:match("^%s*%w%s%s") then  -- Lines starting with key + spaces + text
      vim.api.nvim_buf_add_highlight(buf, ns_id, "NvDashButtons", i - 1, 0, -1)
    end
  end
  
  -- Highlight footer
  for i, line in ipairs(lines) do
    if line:find("Neovim v") then
      vim.api.nvim_buf_add_highlight(buf, ns_id, "NvDashFooter", i - 1, 0, -1)
      break
    end
  end
end

-- Open dashboard
M.open = function()
  M.render()
end

-- Auto-open dashboard for empty buffers (like alpha)
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local should_open = vim.fn.argc() == 0 and vim.fn.line2byte("$") == -1 and not vim.o.insertmode
    if should_open then
      M.open()
    end
  end,
})

-- Set up highlights when colorscheme changes
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = M.setup_highlights,
})

-- Command to manually open dashboard
vim.api.nvim_create_user_command("Dashboard", M.open, {
  desc = "Open NvChad Dashboard"
})

return M