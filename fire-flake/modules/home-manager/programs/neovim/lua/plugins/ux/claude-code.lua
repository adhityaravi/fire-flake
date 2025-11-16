-- Claude Code integration (greggh/claude-code.nvim)
-- Opens Claude Code CLI in terminal and auto-reloads modified files

require("claude-code").setup({
  window = {
    split_ratio = 0.3,
    position = "botright",
    enter_insert = true,
    hide_numbers = true,
    hide_signcolumn = true,
  },
  refresh = {
    enable = true,
    updatetime = 100,
    timer_interval = 1000,
    show_notifications = false, -- Less intrusive
  },
  git = {
    use_git_root = true,
  },
  -- Disable default keymaps (we'll set our own)
  keymaps = {
    toggle = {
      normal = "",
      terminal = "",
      variants = {
        continue = "",
        verbose = "",
      },
    },
    window_navigation = true, -- Keep C-h/j/k/l navigation
    scrolling = true,         -- Keep C-f/C-b scrolling
  },
})

-- Custom keymaps under <leader>aa* (AI - Claude)
vim.keymap.set("n", "<leader>aag", "<cmd>ClaudeCode<CR>", { desc = "Claude: Toggle" })
vim.keymap.set("t", "<leader>aag", "<cmd>ClaudeCode<CR>", { desc = "Claude: Toggle" })
vim.keymap.set("n", "<leader>aac", "<cmd>ClaudeCodeContinue<CR>", { desc = "Claude: Continue conversation" })
vim.keymap.set("n", "<leader>aar", "<cmd>ClaudeCodeResume<CR>", { desc = "Claude: Resume (picker)" })
vim.keymap.set("n", "<leader>aav", "<cmd>ClaudeCodeVerbose<CR>", { desc = "Claude: Verbose mode" })
