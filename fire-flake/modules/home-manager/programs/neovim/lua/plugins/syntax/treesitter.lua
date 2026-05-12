-- Parsers are installed via nix (see plugins.nix). On the nvim-treesitter
-- `main` branch + Neovim 0.12, setup() only configures install paths and is
-- optional — highlighting/indent must be enabled per-buffer via FileType.
-- nvim 0.12 also changed get_parser() to return nil instead of erroring,
-- so the truthy return — not pcall — is the correct guard.

vim.api.nvim_create_autocmd('FileType', {
  callback = function(ev)
    local ft = vim.bo[ev.buf].filetype
    if ft == '' then return end

    local lang = vim.treesitter.language.get_lang(ft) or ft
    local parser = vim.treesitter.get_parser(ev.buf, lang, { error = false })
    if not parser then return end

    if not pcall(vim.treesitter.start, ev.buf, lang) then return end

    vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
