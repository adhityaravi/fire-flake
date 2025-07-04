require('nvim-autopairs').setup({
  check_ts = true,
})

local ok, cmp = pcall(require, 'cmp')
if ok then
  local cmp_autopairs = require('nvim-autopairs.completion.cmp')
  cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
end
