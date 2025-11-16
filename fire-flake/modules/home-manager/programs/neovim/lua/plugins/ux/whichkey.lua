local wk = require("which-key")
wk.setup({
  preset = "helix",
  win = {
    border = "rounded",
  },
})

wk.add({
  { "<leader>h", group = "hydras", icon = "󰕚" },
  { "<leader>g", group = "git", icon = "󰊢" },
  { "<leader>gh", group = "github", icon = "" },
  { "<leader>b", group = "buffers", icon = "󰈚" },
  { "<leader>l", group = "lsp", icon = "󰒕" },
  { "<leader>f", group = "fuzzy-find", icon = "󰭎" },
  { "<leader>t", group = "toggles", icon = "" },
  { "<leader>d", group = "debug", icon = "" },
  { "<leader>r", group = "find-replace", icon = "" },
  { "<leader>p", group = "grapple", icon = "󰄛" },
  { "<leader>q", group = "quick-fix", icon = "" },
  { "<leader>R", group = "REST", icon = "󰖆" },
  { "<leader>o", group = "obsidian", icon = "󰍉" },
  { "<leader>a", group = "AI", icon = "󰧑" },
  { "<leader>aa", group = "claude-code", icon = "" },
  { "<leader>ag", group = "goose", icon = "🪿" },
  { "<leader>ac", group = "copilot", icon = "" },
})
