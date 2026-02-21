{ config, lib, pkgs, ... }:
let
  cfg = config.custom.youtube-music-cli;
in {
  options.custom.youtube-music-cli = {
    enable = lib.mkEnableOption "Enable youtube-music-cli TUI music player for YouTube Music.";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.youtube-music-cli;
      description = "youtube-music-cli package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
