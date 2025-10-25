local api = vim.api
local autocmd = api.nvim_create_autocmd
local state = require "nvchad.themes.state"
local redraw = require("volt").redraw
local utils = require "nvchad.themes.utils"
local nvapi = require "nvchad.themes.api"

local map = function(mode, keys, func, opts)
  for _, key in ipairs(keys) do
    vim.keymap.set(mode, key, func, opts)
  end
end

map("i", { "<C-n>", "<Down>" }, nvapi.move_down, { buffer = state.input_buf })
map("n", { "j", "<Down>" }, nvapi.move_down, { buffer = state.input_buf })
map("i", { "<C-p>", "<Up>" }, nvapi.move_up, { buffer = state.input_buf })
map("n", { "k", "<Up>" }, nvapi.move_up, { buffer = state.input_buf })

map({ "i", "n" }, { "<cr>" }, function()
  state.confirmed = true
  local name = state.themes_shown[state.index]
  
  if name then
    -- Update nvconfig
    require("nvconfig").base46.theme = name
    
    -- Update chadrc if available
    local has_chadrc, chadrc = pcall(require, "chadrc")
    if has_chadrc then
      chadrc.base46.theme = name
    end
    
    -- Apply theme immediately
    utils.reload_theme(name)
    
    -- Save theme preference for persistence
    local theme_path = vim.fn.stdpath("state") .. "/nvchad_theme"
    vim.fn.mkdir(vim.fn.fnamemodify(theme_path, ":h"), "p")
    vim.fn.writefile({ name }, theme_path)
  end

  require("volt").close()
end, { buffer = state.input_buf })

-- delete text
map("i", { "<C-w>" }, function()
  vim.api.nvim_input "<c-s-w>"
end, { buffer = state.input_buf })

-- Note: Close mappings are handled by volt.mappings() in init.lua
-- The volt module automatically sets up "q" and "<Esc>" mappings that call utils.close()
-- We don't need to override them here as that causes infinite recursion

---------------------- autocmds ----------------------

autocmd("TextChangedI", {
  buffer = state.input_buf,

  callback = function()
    if state.scrolled then
      api.nvim_buf_call(state.buf, function()
        vim.cmd "normal! gg"
      end)
    end

    local promptlen = api.nvim_strwidth(state.prompt)
    local input = api.nvim_get_current_line():sub(promptlen + 1, -1)
    input = input:gsub("%s", "")

    state.index = 1

    state.themes_shown = utils.filter(state.val, input)

    api.nvim_set_option_value("modifiable", true, { buf = state.buf })

    for i = 1, #state.val, 1 do
      local emptystr = string.rep(" ", state.w)
      api.nvim_buf_set_lines(state.buf, i - 1, i, false, { emptystr })
    end

    api.nvim_set_option_value("modifiable", false, { buf = state.buf })

    if state.textchanged and #state.themes_shown > 0 then
      utils.reload_theme(state.themes_shown[1])
    end

    redraw(state.buf, "all")
    state.scrolled = false
    state.textchanged = true
  end,
})

