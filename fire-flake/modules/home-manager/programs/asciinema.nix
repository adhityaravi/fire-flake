{ config, lib, pkgs, ... }:

let
  cfg = config.custom.asciinema;
in
{
  options.custom.asciinema = {
    enable = lib.mkEnableOption "Enable asciinema terminal recording";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      asciinema_3
    ];
  };
}
