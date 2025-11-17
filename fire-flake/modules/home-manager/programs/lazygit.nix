{ config, lib, pkgs, ... }:

let
  cfg = config.custom.lazygit;
in
{
  options.custom.lazygit = {
    enable = lib.mkEnableOption "Enable lazygit configuration";

    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional lazygit configuration settings.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.lazygit = {
      enable = true;
      settings = lib.mkMerge [
        {
          keybinding = {
            universal = {
              return = "b";
            };
          };
        }
        cfg.extraSettings
      ];
    };
  };
}
