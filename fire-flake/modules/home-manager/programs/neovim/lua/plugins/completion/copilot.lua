require("copilot").setup({
  suggestion = {
    enabled = true,
    auto_trigger = true,
    debounce = 100,
    keymap = {
      accept = "<Tab>",          -- Accept full suggestion
      accept_word = "<C-Right>", -- Accept one word
      accept_line = "<C-l>",     -- Accept one line
      next = "<M-]>",            -- Next suggestion
      prev = "<M-[>",            -- Previous suggestion
      dismiss = "<Esc>",         -- Dismiss suggestion
    },
  },
  panel = {
    enabled = false,
  },
  filetypes = {
    lua = true,
    python = true,
    go = true,
    nix = true,
    sh = true,
    markdown = true,
    terraform = true,
    yaml = true,
    ["*"] = false,
  },
})

vim.g.copilot_enabled = true -- on by default
function ToggleCopilot()
  vim.g.copilot_enabled = not vim.g.copilot_enabled
  if vim.g.copilot_enabled then
    vim.cmd("Copilot enable")
  else
    vim.cmd("Copilot disable")
  end
end

-- Keymaps under <leader>ac* (AI - Copilot)
vim.keymap.set("n", "<leader>ace", "<cmd>Copilot enable<CR>", { desc = "Copilot: Enable" })
vim.keymap.set("n", "<leader>acd", "<cmd>Copilot disable<CR>", { desc = "Copilot: Disable" })
vim.keymap.set("n", "<leader>acs", "<cmd>Copilot status<CR>", { desc = "Copilot: Status" })
vim.keymap.set("n", "<leader>act", ToggleCopilot, { desc = "Copilot: Toggle" })
