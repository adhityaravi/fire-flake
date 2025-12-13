{ config, lib, pkgs, ... }:
let
  cfg = config.custom.semtools;
in {
  options.custom.semtools = {
    enable = lib.mkEnableOption "Enable semtools semantic search and document parsing utilities.";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.semtools;
      description = "Semtools package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
