{ pkgs, nurpkgs ? {} }:

let
  treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: with plugins; [
    bash
    go
    python
    terraform
    nix
    lua
    json
    yaml
    markdown
    http
  ]);
in

with pkgs.vimPlugins; [
  # Core dependencies
  plenary-nvim
  nvim-web-devicons
  mini-nvim

  # Colorschemes
  everforest
  vague-nvim
  doom-one-nvim

  # UX
  which-key-nvim
  noice-nvim
  hydra-nvim
  auto-save-nvim
  # kulala-nvim  # kulala seems to be causing tressitter issues. i dont use it enough to care rn
  # Fixed version of goose-nvim with updated session metadata handling
  (nurpkgs.goose-nvim.overrideAttrs (oldAttrs: {
    postPatch = ''
      # Fix session.lua to handle new goose CLI JSON format
      cat > lua/goose/session.lua << 'EOF'
local M = {}

function M.get_all_sessions()
  local handle = io.popen('goose session list --format json')
  if not handle then return nil end

  local result = handle:read("*a")
  handle:close()

  local success, sessions = pcall(vim.fn.json_decode, result)
  if not success or not sessions or next(sessions) == nil then return nil end

  local mapped_sessions = vim.tbl_map(function(session)
    -- Add defensive checks for required fields
    if not session then return nil end
    
    return {
      workspace = session.working_dir or "",
      description = session.description or "",
      message_count = session.message_count or 0,
      tokens = session.total_tokens,
      modified = session.updated_at or session.modified or "",
      name = session.id or "",
      path = session.path or ""
    }
  end, sessions)
  
  -- Filter out any nil entries
  return vim.tbl_filter(function(session)
    return session ~= nil
  end, mapped_sessions)
end

function M.get_all_workspace_sessions()
  local sessions = M.get_all_sessions()
  if not sessions then return nil end

  local workspace = vim.fn.getcwd()
  sessions = vim.tbl_filter(function(session)
    return session.workspace == workspace
  end, sessions)

  table.sort(sessions, function(a, b)
    return a.modified > b.modified
  end)

  return sessions
end

function M.get_last_workspace_session()
  local sessions = M.get_all_workspace_sessions()
  if not sessions then return nil end
  return sessions[1]
end

function M.get_by_name(name)
  local sessions = M.get_all_sessions()
  if not sessions then return nil end

  for _, session in ipairs(sessions) do
    if session.name == name then
      return session
    end
  end

  return nil
end

return M
EOF
    '';
  }))
  pkgs.vimPlugins.render-markdown-nvim

  # UI
  lualine-nvim
  toggleterm-nvim
  alpha-nvim
  persistence-nvim
  bufferline-nvim
  smart-splits-nvim
  # leap-nvim
  indent-blankline-nvim

  # Syntax highlighting
  treesitter

  # LSP support
  nvim-lspconfig
  mason-nvim
  mason-lspconfig-nvim
  lspkind-nvim

  # Autocompletion
  nvim-cmp
  cmp-nvim-lsp
  cmp-buffer
  cmp-path
  cmp-cmdline
  cmp_luasnip
  copilot-cmp
  copilot-lua
  luasnip
  friendly-snippets
  nvim-autopairs
  nvim-spider

  # Formatting
  conform-nvim

  # Search and navigation
  telescope-nvim
  telescope-project-nvim
  telescope-file-browser-nvim
  nvim-spectre
  todo-comments-nvim
  grapple-nvim
  # obsidian-nvim

  # File explorer
  nvim-tree-lua
  oil-nvim

  # Debugging
  nvim-dap
  nvim-dap-python
  nvim-dap-go
  nvim-dap-ui
  neotest
  neotest-go
  neotest-python
  neotest-plenary
  nvim-bqf

  # Git integration
  gitsigns-nvim
  lazygit-nvim
  octo-nvim
]
