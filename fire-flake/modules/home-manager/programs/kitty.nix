{ pkgs, ... }:

let
  # kittyTheme = pkgs.fetchFromGitHub {
  #   owner = "dexpota";
  #   repo = "kitty-themes";
  #   rev = "master";
  #   sha256 = "sha256-RcDmZ1fbNX18+X3xCqqdRbD+XYPsgNte1IXUNt6CxIA=";
  # };
in {
  programs.kitty = {
    enable = false;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 13;
    };

    settings = {
      background_opacity = "0.95";
      confirm_os_window_close = 0;
      enable_audio_bell = "no";
      cursor_shape = "block";
    };

    keybindings = {
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+e" = "launch --cwd=current";
    };

    themeFile = "Dracula";
  };

  home.packages = with pkgs; [
    nerd-fonts._0xproto
    nerd-fonts.droid-sans-mono
    nerd-fonts.jetbrains-mono
    libGL
    libglvnd
    mesa
  ];

  home.sessionVariables = {
    KITTY_USE_SOFTWARE_RENDERING = "1";
  };
}
