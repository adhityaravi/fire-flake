{
  config,
  lib,
  pkgs,
  userVars,
  nurpkgs,
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
    ../../modules/home-manager/programs/kitty-terminfo.nix
    ../../modules/home-manager/programs/tailscale.nix
    ../../modules/home-manager/common.nix
    # NOTE: Intel NUC — dedicated Maki brain (Canonical K8s, NATS, Postgres)
  ];

  home = {
    username = userVars.username;
    homeDirectory = userVars.homeDirectory;
    stateVersion = userVars.stateVersion;
  };

  # Common CLI tools — trimmed for headless Maki box
  custom.common = {
    enable = true;
    # No fonts on headless server
    fonts = [];
    # No media processing
    mediaTools = [];
    # No VMs — K8s handles workloads
    vmTools = [];
    # Slim dev tools — Maki runs in K8s, not on host
    devTools = with pkgs; [
      jq
      yq-go
      curl
      wget
      kubectl
      tree
      shellcheck
      sops
      age
      opentofu
      terragrunt
    ];
  };

  # Git
  custom.git = {
    enable = true;
    userName = userVars.git.name;
    userEmail = userVars.git.email;
  };

  # Lazygit
  custom.lazygit.enable = true;

  # Just — maki infra and tailscale recipes
  custom.just = {
    enable = true;
    recipes.tailscale = true;
    recipes.maki = true;
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

  # Fish shell
  custom.fish = {
    enable = true;
    setDefault = true;
  };

  # Starship prompt
  custom.starship.enable = true;

  # k9s TUI for Kubernetes
  custom.k9s.enable = true;

  # Kitty terminfo for SSH sessions
  custom.kitty-terminfo.enable = true;

  # Tailscale
  custom.tailscale.enable = true;

  # SSH agent for headless server
  services.ssh-agent.enable = true;
}
