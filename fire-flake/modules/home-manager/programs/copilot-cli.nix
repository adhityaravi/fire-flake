{ config, lib, pkgs, ... }:
let
  cfg = config.custom.copilot-cli;
in {
  options.custom.copilot-cli = {
    enable = lib.mkEnableOption "Enable github copilot cli.";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.github-copilot-cli;
      description = "Github copilot cli package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
