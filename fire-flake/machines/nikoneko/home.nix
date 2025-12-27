{
  config,
  lib,
  pkgs,
  userVars,
  ...
}: {
  imports = [
    # CLI tools and dev environment
    ../../modules/home-manager/programs/git.nix
    ../../modules/home-manager/programs/lazygit.nix
    ../../modules/home-manager/programs/just.nix
    ../../modules/home-manager/programs/neovim.nix
    ../../modules/home-manager/programs/goose.nix
    ../../modules/home-manager/programs/claude-code.nix
    ../../modules/home-manager/programs/fish.nix
    ../../modules/home-manager/programs/starship/starship.nix
    ../../modules/home-manager/programs/k9s.nix
    ../../modules/home-manager/programs/kitty-terminfo.nix
    ../../modules/home-manager/programs/copilot-cli.nix
    ../../modules/home-manager/programs/semtools.nix
    ../../modules/home-manager/programs/tailscale.nix
    ../../modules/home-manager/common.nix
    # NOTE: No GUI apps (kitty, obsidian) - this is a headless SSH workstation
  ];

  home = {
    username = userVars.username;
    homeDirectory = userVars.homeDirectory;
    stateVersion = userVars.stateVersion;
  };

  # Common CLI tools, fonts, dev tools
  custom.common.enable = true;

  # Git
  custom.git = {
    enable = true;
    userName = userVars.git.name;
    userEmail = userVars.git.email;
  };

  # Lazygit
  custom.lazygit.enable = true;

  # Just task runner with charm-dev recipes
  custom.just = {
    enable = true;
    # charm-dev for juju/microk8s/charmcraft development
    recipes.charm-dev = true;
    recipes.tailscale = true;
  };

  # Neovim
  custom.neovim.enable = true;

  # Goose CLI (disabled by default)
  custom.goose.enable = false;

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
  };

  # Fish shell
  custom.fish.enable = true;

  # Starship prompt
  custom.starship.enable = true;

  # k9s TUI for Kubernetes
  custom.k9s.enable = true;

  # Kitty terminfo for SSH sessions
  custom.kitty-terminfo.enable = true;

  # GitHub Copilot CLI
  custom.copilot-cli.enable = true;

  # Semtools semantic search
  custom.semtools.enable = true;

  # Tailscale
  custom.tailscale.enable = true;
}
