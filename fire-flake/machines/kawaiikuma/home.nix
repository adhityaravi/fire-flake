{
  config,
  lib,
  pkgs,
  userVars,
  ...
}: {
  imports = [
    ../../modules/home-manager/programs/git.nix
    ../../modules/home-manager/programs/lazygit.nix
    ../../modules/home-manager/programs/just.nix
    ../../modules/home-manager/programs/neovim.nix
    ../../modules/home-manager/programs/claude-code.nix
    ../../modules/home-manager/programs/fish.nix
    ../../modules/home-manager/programs/starship/starship.nix
    ../../modules/home-manager/programs/k9s.nix
    ../../modules/home-manager/programs/copilot-cli.nix
    ../../modules/home-manager/programs/semtools.nix
    ../../modules/home-manager/programs/tailscale.nix
    ../../modules/home-manager/programs/asciinema.nix
    ../../modules/home-manager/programs/ksnip.nix
    ../../modules/home-manager/programs/svg-term.nix
    ../../modules/home-manager/common.nix
  ];

  home = {
    username = userVars.username;
    homeDirectory = userVars.homeDirectory;
    stateVersion = userVars.stateVersion;
  };

  # Add your own tool selections if needed
  # Its also possible to override the default common tools. Not recommended.
  custom.common = {
    enable = true;
    # Example: add extra tools
    #userTools = with pkgs; [
    #  git
    #  jq
    #  curl
    #  wget
    #  direnv
    #  nixpkgs-fmt
    #  shellcheck
    #  tree
    #];
  };

  # Git
  custom.git = {
    enable = true;
    userName = userVars.git.name;
    userEmail = userVars.git.email;
  };

  # Lazygit
  custom.lazygit.enable = true;

  # Just task runner
  custom.just = {
    enable = true;
    # TODO: Move charm-dev to a more niche profile.
    # NOTE: charm-dev requires sudo access and snaps.
    recipes.charm-dev = true;
    recipes.tailscale = true;
    recipes.ephemeral-vm = true;
  };

  # Neovim
  custom.neovim = {
    enable = true;

    # Example: Add extra plugins
    #extraPlugins = with pkgs.vimPlugins; [
    #  catppuccin-nvim
    #];

    # Example: Add extra Lua config
    #extraLuaConfig = ''
    #  vim.cmd("colorscheme catppuccin")
    #  require("catppuccin").setup({})
    #'';
  };

  # Claude Code CLI
  custom.claudeCode = {
    enable = true;
    settings = {
      alwaysThinkingEnabled = true;
      statusLine = {
        type = "command";
        command = "npx -y @owloops/claude-powerline@latest --style=powerline";
      };
    };
    marketplaces = {
      claude-code-workflows = {
        owner = "wshobson";
        repo = "agents";
        rev = "c7ad381360bb8a2263aa42e25f81dc41161bf7d9";
        hash = "sha256-tF1ambblLu/BxCdNf1H2GqhhtkFAZ/kvNb+wlaTTdy4=";
        plugins = [
          "python-development"
          "kubernetes-operations"
          "security-scanning"
          "code-review-ai"
        ];
      };
    };
    #extraEnv = {
    #  CLAUDE_CODE_MODEL = "default";
    #};
  };

  # Fish shell
  custom.fish.enable = true;

  # Starship prompt
  custom.starship.enable = true;

  # k9s TUI
  custom.k9s.enable = true;

  # GitHub Copilot CLI
  custom.copilot-cli.enable = true;

  # Semtools semantic search
  custom.semtools.enable = true;

  # Tailscale
  custom.tailscale.enable = true;

  # Asciinema terminal recording
  custom.asciinema.enable = true;

  # Ksnip screenshot and annotation tool
  custom.ksnip.enable = true;

  # SVG-term for asciinema to SVG conversion
  custom.svg-term.enable = true;
}
