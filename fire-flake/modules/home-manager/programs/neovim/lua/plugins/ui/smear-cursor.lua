-- Smear Cursor Configuration with Dynamic Preset Switching
-- Presets can be switched at runtime using keybindings

-- Define all available presets
local presets = {
  -- Default: Balanced smear effect with standard settings
  default = {
    cursor_color = "#ffffff",
    smear_between_buffers = true,
    smear_between_neighbor_lines = true,
    scroll_buffer_space = true,
    legacy_computing_symbols_support = false,
    smear_insert_mode = true,
  },

  -- Faster: Snappier animations with higher stiffness
  faster = {
    cursor_color = "#ffffff",
    stiffness = 0.8,
    trailing_stiffness = 0.6,
    stiffness_insert_mode = 0.7,
    trailing_stiffness_insert_mode = 0.7,
    damping = 0.95,
    damping_insert_mode = 0.95,
    distance_stop_animating = 0.5,
    time_interval = 7,
  },

  -- Smooth Caret: Rectangular cursor with smooth movement, no smear trail
  smooth_caret = {
    cursor_color = "#ffffff",
    stiffness = 0.5,
    trailing_stiffness = 0.5,
    matrix_pixel_threshold = 0.5,
  },

  -- Fire Hazard: Extreme configuration with particles and color effects
  fire_hazard = {
    cursor_color = "#ff4000",
    particles_enabled = true,
    stiffness = 0.5,
    trailing_stiffness = 0.2,
    trailing_exponent = 5,
    damping = 0.6,
    gradient_exponent = 0,
    gamma = 1,
    never_draw_over_target = true,
    hide_target_hack = true,
    particle_spread = 1,
    particles_per_second = 500,
    particles_per_length = 50,
    particle_max_lifetime = 800,
    particle_max_initial_velocity = 20,
    particle_velocity_from_cursor = 0.5,
    particle_damping = 0.15,
    particle_gravity = -50,
    min_distance_emit_particles = 0,
  },
}

-- Function to switch between presets dynamically
local function switch_preset(preset_name)
  local config = presets[preset_name]
  if config then
    require("smear_cursor").setup(config)
    vim.notify("Smear cursor: " .. preset_name:gsub("_", " "), vim.log.levels.INFO)
  else
    vim.notify("Unknown preset: " .. preset_name, vim.log.levels.ERROR)
  end
end

-- Initialize with default preset
require("smear_cursor").setup(presets.default)

-- Keybindings for preset switching
vim.keymap.set("n", "<leader>kd", function()
  switch_preset("default")
end, { desc = "Default preset" })

-- Fire hazard isnt working yet, because the latest version isnt released to nixpkgs.
-- TODO: uncomment when the new version is available.
-- vim.keymap.set("n", "<leader>kf", function()
--   switch_preset("fire_hazard")
-- end, { desc = "Fire hazard preset" })

vim.keymap.set("n", "<leader>ks", function()
  switch_preset("smooth_caret")
end, { desc = "Smooth caret preset" })

vim.keymap.set("n", "<leader>kt", function()
  switch_preset("faster")
end, { desc = "Turbo/faster preset" })

vim.keymap.set("n", "<leader>kx", "<cmd>SmearCursorToggle<CR>", { desc = "Toggle smear cursor" })
