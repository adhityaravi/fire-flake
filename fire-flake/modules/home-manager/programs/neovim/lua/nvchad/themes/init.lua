local M = {}
local api = vim.api
local volt = require "volt"
local ui = require "nvchad.themes.ui"
local state = require "nvchad.themes.state"
local colors = dofile(vim.g.base46_cache .. "colors")

-- Custom close function that ensures state cleanup
local function close_with_cleanup()
  pcall(function()
    -- Call volt.close first
    volt.close()
    
    -- Get fresh reference to state module to ensure we're modifying the right instance
    local current_state = require("nvchad.themes.state")
    
    -- Reset state variables to prevent issues on next open
    current_state.buf = nil
    current_state.input_buf = nil
    current_state.win = nil
    current_state.input_win = nil
    current_state.confirmed = nil
    current_state.textchanged = false
    current_state.scrolled = false
    current_state.index = 1
    
    -- Debug: force reload the theme if needed
    if not current_state.confirmed then
      local has_chadrc, chadrc = pcall(require, "chadrc")
      if has_chadrc then
        require("nvchad.themes.utils").reload_theme(chadrc.base46.theme)
      end
    end
    vim.cmd.stopinsert()
  end)
end

state.ns = api.nvim_create_namespace "NvThemes"

if not state.val then
  state.val = require("nvchad.utils").list_themes()
  state.themes_shown = state.val
end

local gen_word_pad = function()
  local largest = 0

  -- Ensure we have a valid limit
  local limit = state.limit[state.style]
  if not limit then
    state.longest_name = 15 -- reasonable fallback
    return
  end

  for i = state.index, math.min(state.index + limit, #state.val) do
    if state.val[i] then
      local namelen = #state.val[i]
      if namelen > largest then
        largest = namelen
      end
    end
  end

  state.longest_name = largest
end

M.open = function(opts)
  opts = opts or {}
  
  -- Clean up any stale state from previous sessions
  if state.buf and api.nvim_buf_is_valid(state.buf) then
    pcall(api.nvim_buf_delete, state.buf, { force = true })
  end
  if state.input_buf and api.nvim_buf_is_valid(state.input_buf) then
    pcall(api.nvim_buf_delete, state.input_buf, { force = true })
  end
  if state.win and api.nvim_win_is_valid(state.win) then
    pcall(api.nvim_win_close, state.win, true)
  end
  if state.input_win and api.nvim_win_is_valid(state.input_win) then
    pcall(api.nvim_win_close, state.input_win, true)
  end
  
  -- Reset state before creating new UI
  state.buf = nil
  state.input_buf = nil
  state.win = nil
  state.input_win = nil
  state.confirmed = nil
  state.textchanged = false
  state.scrolled = false
  state.index = 1
  
  -- Create new buffers
  state.buf = api.nvim_create_buf(false, true)
  state.input_buf = api.nvim_create_buf(false, true)

  state.style = opts.style or "bordered"

  local style = state.style

  state.icons.user = opts.icon
  state.icon = state.icons.user or state.icons[style]

  gen_word_pad()

  -- Ensure state.icon is valid before using nvim_strwidth
  if not state.icon or type(state.icon) ~= "string" then
    state.icon = "█" -- fallback icon
  end

  state.w = state.longest_name + state.word_gap + (#state.order * api.nvim_strwidth(state.icon)) + (state.xpad * 2)

  if style == "compact" then
    state.w = state.w + 4 -- 1 x 2 padding on left/right + 2 of scrollbar
  end

  if style == "flat" then
    state.w = state.w + 8
  end

  volt.gen_data {
    {
      buf = state.buf,
      layout = { { name = "themes", lines = function() 
        local ui_func = ui[state.style]
        if ui_func then
          return ui_func()
        else
          return {{ {"No themes available", "Error"} }}
        end
      end } },
      xpad = state.xpad,
      ns = state.ns,
    },
  }

  local h = state.limit[style] + 1

  if style == "flat" or style == "bordered" then
    local step = state.scroll_step[state.style]
    h = (h * step) - 5
  end

  local input_win_opts = {
    row = math.floor((vim.o.lines - h) / 2),
    col = math.floor((vim.o.columns - state.w) / 2),
    width = state.w,
    height = 1,
    relative = "editor",
    style = "minimal",
    border = "single",
  }

  if style == "flat" or style == "bordered" then
    input_win_opts.row = input_win_opts.row - 2
  end

  state.input_win = api.nvim_open_win(state.input_buf, true, input_win_opts)

  state.win = api.nvim_open_win(state.buf, false, {
    row = 2,
    col = -1,
    width = state.w,
    height = ((style == "flat" or style == "bordered") and h + 2) or h,
    relative = "win",
    style = "minimal",
    border = "single",
  })

  vim.bo[state.input_buf].buftype = "prompt"
  vim.fn.prompt_setprompt(state.input_buf, state.prompt)
  vim.cmd "startinsert"

  if opts.border then
    api.nvim_set_hl(state.ns, "FloatBorder", { link = "Comment" })
    api.nvim_set_hl(state.ns, "Normal", { link = "Normal" })
    vim.wo[state.input_win].winhl = "Normal:Normal"
  else
    vim.wo[state.input_win].winhl = "Normal:ExBlack2Bg,FloatBorder:ExBlack2Border"
    api.nvim_set_hl(state.ns, "Normal", { link = "ExDarkBg" })
    api.nvim_set_hl(state.ns, "FloatBorder", { link = "ExDarkBorder" })
  end

  api.nvim_set_hl(state.ns, "NScrollbarOff", { fg = colors.one_bg2 })
  api.nvim_win_set_hl_ns(state.win, state.ns)
  api.nvim_set_current_win(state.input_win)
  
  -- Set cursor position after window is created
  api.nvim_win_set_cursor(state.input_win, { 1, 6 })

  local volt_opts = { h = #state.val, w = state.w }

  if state.style == "flat" or state.style == "bordered" then
    local step = state.scroll_step[state.style]
    volt_opts.h = (volt_opts.h * step) + 2
  end

  volt.run(state.buf, volt_opts)

  ----------------- keymaps --------------------------
  -- Set up close keymaps directly instead of using volt.mappings to avoid conflicts
  vim.keymap.set({ "n", "i" }, "q", close_with_cleanup, { buffer = state.input_buf, nowait = true })
  vim.keymap.set({ "n", "i" }, "<Esc>", close_with_cleanup, { buffer = state.input_buf, nowait = true })
  vim.keymap.set("n", "q", close_with_cleanup, { buffer = state.buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close_with_cleanup, { buffer = state.buf, nowait = true })

  require "nvchad.themes.mappings"

  if opts.mappings then
    opts.mappings(state.input_buf)
  end
end

return M