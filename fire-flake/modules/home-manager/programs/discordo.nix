{ config, lib, pkgs, ... }:

let
  cfg = config.custom.discordo;
in
{
  options.custom.discordo = {
    enable = lib.mkEnableOption "Enable discordo TUI client for Discord";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      discordo
    ];
  };
}
