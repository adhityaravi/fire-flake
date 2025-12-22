{ config, lib, pkgs, ... }:

let
  cfg = config.custom.fish;

in {
  options.custom.fish = {
    enable = lib.mkEnableOption "Enable fish shell";
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        set -g fish_greeting ""
        if type -q fortune && type -q cowsay && type -q lolcat
          fortune -a | cowsay
        end
      '';
      shellAliases = {
        jg = "just -g";
      };
    };

    home.packages = with pkgs; [ fish fortune cowsay ];
  };
}
