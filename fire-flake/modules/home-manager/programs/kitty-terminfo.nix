{ config, lib, pkgs, ... }:

let
  cfg = config.custom.kitty-terminfo;
in {
  options.custom.kitty-terminfo = {
    enable = lib.mkEnableOption "Enable kitty terminfo for SSH sessions from kitty terminal";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.kitty.terminfo ];
  };
}
