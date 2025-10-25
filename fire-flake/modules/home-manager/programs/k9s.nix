{ config, lib, pkgs, ... }:
let
  cfg = config.custom.k9s;
in {
  options.custom.k9s = {
    enable = lib.mkEnableOption "Enable k9s.";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.k9s;
      description = "k9s package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
