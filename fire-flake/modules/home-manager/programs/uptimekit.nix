{ config, lib, pkgs, ... }:
let
  cfg = config.custom.uptimekit;
in {
  options.custom.uptimekit = {
    enable = lib.mkEnableOption "Enable uptimekit CLI for monitoring website/server health.";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.uptimekit;
      description = "Uptimekit package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
