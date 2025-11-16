require("goose").setup({
	prefered_picker = "telescope",
	default_global_keymaps = false,
	providers = {
		github_copilot = {
			"gpt-4.1",  -- Current default model (Aug 2025)
			"gpt-4o",   -- Keeping for compatibility
		},
	},
})

-- Helper for calling goose api functions
local function Goose(action)
	return function(...)
		require("goose.api")[action](...)
	end
end

-- Keymaps under <leader>ag* (AI - Goose)
vim.keymap.set("n", "<leader>agg", Goose("toggle"), { desc = "Goose: Toggle UI" })
vim.keymap.set("n", "<leader>agi", Goose("open_input"), { desc = "Goose: Open input" })
vim.keymap.set("n", "<leader>agI", Goose("open_input_new_session"), { desc = "Goose: New session input" })
vim.keymap.set("n", "<leader>ago", Goose("open_output"), { desc = "Goose: Open output" })
vim.keymap.set("n", "<leader>agt", Goose("toggle_focus"), { desc = "Goose: Toggle focus" })
vim.keymap.set("n", "<leader>agq", Goose("close"), { desc = "Goose: Close UI" })
vim.keymap.set("n", "<leader>agf", Goose("toggle_fullscreen"), { desc = "Goose: Toggle fullscreen" })
vim.keymap.set("n", "<leader>ags", Goose("select_session"), { desc = "Goose: Select session" })
vim.keymap.set("n", "<leader>agc", Goose("goose_mode_chat"), { desc = "Goose: Chat mode" })
vim.keymap.set("n", "<leader>aga", Goose("goose_mode_auto"), { desc = "Goose: Auto mode" })
vim.keymap.set("n", "<leader>agp", Goose("configure_provider"), { desc = "Goose: Choose provider" })
vim.keymap.set("n", "<leader>agd", Goose("diff_open"), { desc = "Goose: Diff open" })
vim.keymap.set("n", "<leader>ag]", Goose("diff_next"), { desc = "Goose: Diff next file" })
vim.keymap.set("n", "<leader>ag[", Goose("diff_prev"), { desc = "Goose: Diff previous file" })
vim.keymap.set("n", "<leader>agx", Goose("diff_close"), { desc = "Goose: Diff close" })
vim.keymap.set("n", "<leader>agra", Goose("diff_revert_all"), { desc = "Goose: Revert all changes" })
vim.keymap.set("n", "<leader>agrt", Goose("diff_revert_this"), { desc = "Goose: Revert this file" })
