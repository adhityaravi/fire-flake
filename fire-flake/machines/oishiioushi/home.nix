{
  config,
  lib,
  pkgs,
  userVars,
  ...
}: {
  imports = [
    ../../modules/home-manager/programs/git.nix
    ../../modules/home-manager/programs/just.nix
    ../../modules/home-manager/programs/fish.nix
    ../../modules/home-manager/programs/gh-runner.nix
    ../../modules/home-manager/programs/tailscale.nix
    ../../modules/home-manager/common.nix
  ];

  home = {
    username = userVars.username;
    homeDirectory = userVars.homeDirectory;
    stateVersion = userVars.stateVersion;
  };

  # Minimal common tools for CI
  custom.common = {
    enable = true;
  };

  # Git (required for checkout)
  custom.git = {
    enable = true;
    userName = userVars.git.name;
    userEmail = userVars.git.email;
  };

  # Just task runner with runner recipes
  custom.just = {
    enable = true;
    recipes.runner = true;
    recipes.charm-dev = true;
    recipes.tailscale = true;
  };

  # Fish shell
  custom.fish.enable = true;

  # GitHub Actions runner
  custom.ghRunner.enable = true;

  # Tailscale VPN
  custom.tailscale.enable = true;
}
