{ config, lib, pkgs, ... }:

let
  cfg = config.custom.svg-term;
in
{
  options.custom.svg-term = {
    enable = lib.mkEnableOption "Enable svg-term for converting asciinema recordings to SVG";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      svg-term
    ];
  };
}
