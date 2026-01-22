{ config, lib, pkgs, ... }:

let
  cfg = config.custom.ksnip;
in
{
  options.custom.ksnip = {
    enable = lib.mkEnableOption "Enable ksnip screenshot and annotation tool";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ksnip
    ];
  };
}
