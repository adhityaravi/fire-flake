require('conform').setup({
  format_on_save = {
    lsp_fallback = true,
  },
  formatters_by_ft = {
    python = { 'ruff_fix', 'ruff_format' },
    go = { 'goimports', 'gofmt' },
    lua = { 'stylua' },
    rust = { 'rustfmt' },
    yaml = { 'yamlfmt' },
    markdown = { 'prettier' },
    nix = { 'alejandra' },
    ['*'] = { 'trim_whitespace' },
  },
})
