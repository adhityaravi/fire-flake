{ config, lib, pkgs, ... }:
let
  cfg = config.custom.waveterm;
in {
  options.custom.waveterm = {
    enable = lib.mkEnableOption "Enable waveterm.";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.waveterm;
      description = "waveterm package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
