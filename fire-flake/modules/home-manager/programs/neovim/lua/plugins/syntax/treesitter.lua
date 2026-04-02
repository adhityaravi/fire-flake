-- treesitter parsers are installed through nix (see plugins.nix)
require('nvim-treesitter').setup()

-- Enable treesitter highlighting and indentation for all filetypes with parsers
vim.api.nvim_create_autocmd('FileType', {
  callback = function(ev)
    if pcall(vim.treesitter.get_parser, ev.buf) then
      vim.treesitter.start(ev.buf)
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
