{ config, pkgs, lib, ... }:

{
  options.custom.common = {
    enable = lib.mkEnableOption "Enable common tools and utilities";
    
    cliTools = lib.mkOption {
      type = with lib.types; listOf package;
      default = with pkgs; [
        ripgrep
        fd
        fzf
        gh
        pay-respects
      ];
      description = "Common CLI tools useful across programs.";
    };

    fonts = lib.mkOption {
      type = with lib.types; listOf package;
      default = with pkgs.nerd-fonts; [
        jetbrains-mono 
        fira-code 
        hack 
      ];
      description = "Fonts commonly used across programs, including full Nerd Fonts set.";
    };

    devTools = lib.mkOption {
      type = with lib.types; listOf package;
      default = with pkgs; [
        jq
        curl
        wget
        direnv
        nixpkgs-fmt
        shellcheck
        tree
        nodejs
        kubectl
      ];
      description = "Development tools shared across environments.";
    };

    mediaTools = lib.mkOption {
      type = with lib.types; listOf package;
      default = with pkgs; [
        ffmpeg
        imagemagick
        exiftool
        mediainfo
        peek
      ];
      description = "Media-related tools (e.g. ffmpeg, imagemagick).";
    };

    networkTools = lib.mkOption {
      type = with lib.types; listOf package;
      default = with pkgs; [
        mtr
        nmap
        iperf3
        dnsutils
        inetutils
      ];
      description = "Networking tools (e.g. mtr, nmap, curl, iperf3).";
    };

    systemUtils = lib.mkOption {
      type = with lib.types; listOf package;
      default = with pkgs; [
        lsof
        iotop
        ncdu
        btop
        file
        psmisc
        xz
        unzip
        lm_sensors
      ];
      description = "Low-level system utilities (e.g. lsof, htop, iotop).";
    };

    userTools = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      description = "User specific tools that can be added by users.";
    };
  };

  config = lib.mkIf config.custom.common.enable {
    home.sessionVariables = {
      EDITOR = "nvim";
      LANG = "en_US.UTF-8";
    };

    home.packages =
      config.custom.common.cliTools
      ++ config.custom.common.fonts
      ++ config.custom.common.devTools
      ++ config.custom.common.mediaTools
      ++ config.custom.common.networkTools
      ++ config.custom.common.systemUtils
      ++ config.custom.common.userTools;
  };
}

