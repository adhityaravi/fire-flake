require("neotest").setup({
  adapters = {
    require("neotest-python"),
    require("neotest-go"),
    require("neotest-plenary"),
  },
})

-- Keymaps
vim.keymap.set("n", "<leader>dt", function() require('neotest').run.run() end, { silent = true, desc = "Run Nearest Test" })
vim.keymap.set("n", "<leader>df", function() require('neotest').run.run(vim.fn.expand('%')) end, { silent = true, desc = "Run Test File" })
vim.keymap.set("n", "<leader>do", function() require('neotest').output.open({ enter = true }) end, { silent = true, desc = "Open Test Output" })
vim.keymap.set("n", "<leader>ds", function() require('neotest').summary.toggle() end, { silent = true, desc = "Toggle Test Summary" })

