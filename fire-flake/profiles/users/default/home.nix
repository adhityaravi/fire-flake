{
  config,
  lib,
  pkgs,
  userVars,
  ...
}: {
  imports = [
    ../../../modules/home-manager/programs/git.nix
    ../../../modules/home-manager/programs/lazygit.nix
    ../../../modules/home-manager/programs/just.nix
    ../../../modules/home-manager/programs/kitty.nix
    ../../../modules/home-manager/programs/neovim.nix
    ../../../modules/home-manager/programs/obsidian.nix
    ../../../modules/home-manager/programs/goose.nix
    ../../../modules/home-manager/programs/claude-code.nix
    ../../../modules/home-manager/programs/fish.nix
    ../../../modules/home-manager/programs/starship/starship.nix
    ../../../modules/home-manager/programs/k9s.nix
    ../../../modules/home-manager/programs/copilot-cli.nix
    ../../../modules/home-manager/common.nix
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
  };

  # Neovim
  custom.neovim = {
    enable = true;

    # obsidianVaultPaths = userVars.obsidian.vaultPaths;

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

  # Obsidian
  custom.obsidian = {
    enable = false;
    # vaultPaths = userVars.obsidian.vaultPaths;
  };

  # Goose CLI
  custom.goose = {
    enable = false;
    # # lead model
    # leadProvider = "github_copilot";
    # leadModel = "gpt-4.1";
    # # worker model (using Copilot to avoid Anthropic API costs)
    # provider = "github_copilot";
    # model = "gpt-4o";
    #extraEnv = {
    #  GOOSE_TEMPERATURE = "0.7";
    #};
  };

  # Claude Code CLI
  custom.claudeCode = {
    enable = true;
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
}
