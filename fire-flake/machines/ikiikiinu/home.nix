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
    ../../modules/home-manager/programs/claude-code.nix
    ../../modules/home-manager/programs/fish.nix
    ../../modules/home-manager/programs/starship/starship.nix
    ../../modules/home-manager/programs/k9s.nix
    ../../modules/home-manager/programs/kitty-terminfo.nix
    ../../modules/home-manager/programs/tailscale.nix
    ../../modules/home-manager/common.nix
    # NOTE: Headless Ubuntu server - home lab for media/self-hosted services
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

  # Just task runner with charm-dev and lab recipes
  custom.just = {
    enable = true;
    recipes.charm-dev = true;
    recipes.tailscale = true;
    recipes.lab = true;
  };

  # Neovim
  custom.neovim.enable = true;

  # Claude Code CLI
  custom.claudeCode = {
    enable = true;
    settings = {
      alwaysThinkingEnabled = true;
    };
  };

  # Fish shell (use chsh to set as default - no LDAP)
  custom.fish.enable = true;

  # Starship prompt
  custom.starship.enable = true;

  # k9s TUI for Kubernetes (no LDAP workaround needed)
  custom.k9s.enable = true;

  # Kitty terminfo for SSH sessions
  custom.kitty-terminfo.enable = true;

  # Tailscale
  custom.tailscale.enable = true;
}
