require("telescope").setup {}

-- Load extensions
require("telescope").load_extension("file_browser")
require("telescope").load_extension("grapple")
require("telescope").load_extension("project")

-- Load our custom themes extension (NvChad UI removed to avoid conflicts)
require("telescope").load_extension("themes")

-- Keymaps
local function telescope(cmd)
  vim.cmd("Telescope " .. cmd)
end

vim.keymap.set("n", "<leader>ff", function() telescope("find_files") end, { desc = "Find files" })
vim.keymap.set("n", "<leader>fr", function() telescope("oldfiles") end, { desc = "Recent files" })
vim.keymap.set("n", "<leader>fg", function() telescope("live_grep") end, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", function() telescope("buffers") end, { desc = "Open buffers" })
vim.keymap.set("n", "<leader>fh", function() telescope("help_tags") end, { desc = "Help tags" })
vim.keymap.set("n", "<leader>fc", function() telescope("current_buffer_fuzzy_find") end, { desc = "Find in current buffer" })
vim.keymap.set("n", "<leader>fd", function() telescope("diagnostics") end, { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>fm", function() telescope("marks") end, { desc = "Jump to mark" })
vim.keymap.set("n", "<leader>fp", function() telescope("project") end, { desc = "Projects" })
vim.keymap.set("n", "<leader>fs", function() telescope("grapple tags") end, { desc = "Grapple tags" })
vim.keymap.set("n", "<leader>fz", function() telescope("themes") end, { desc = "Themes" })
vim.keymap.set("n", "<leader>th", "<cmd>Themes<CR>", { desc = "Themes UI" })
vim.keymap.set("n", "<leader>tH", "<cmd>Themes compact<CR>", { desc = "Themes UI (Compact)" })
vim.keymap.set("n", "<leader>tb", "<cmd>Themes bordered<CR>", { desc = "Themes UI (Bordered)" })
vim.keymap.set("n", "<leader>ft", function() telescope("treesitter") end, { desc = "Symbols (Treesitter)" })
vim.keymap.set("n", "<leader>fT", "<cmd>TodoTelescope<CR>", { desc = "Search TODOs" })

