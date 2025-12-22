{ config, lib, pkgs, ... }:
let
  cfg = config.custom.ghRunner;
in
{
  options.custom.ghRunner = {
    enable = lib.mkEnableOption "Enable GitHub Actions self-hosted runner.";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.github-runner;
      description = "GitHub runner package to install.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        git
        curl
        jq
        gh
        nodejs
      ];
      description = "Extra packages commonly needed by CI jobs.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ] ++ cfg.extraPackages;
  };
}
