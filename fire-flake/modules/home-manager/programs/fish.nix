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
      loginShellInit = ''
        # Add nix paths for login shells (needed when fish is default shell)
        fish_add_path --prepend ~/.nix-profile/bin /nix/var/nix/profiles/default/bin
      '';
      interactiveShellInit = ''
        set -g fish_greeting ""
        if type -q fortune && type -q cowsay && type -q lolcat
          fortune -a | cowsay
        end
      '';
      shellAliases = {
        jg = "just -g";
        snn = "kitten ssh 'adhitya.ravi@canonical.com'@nikoneko";
        sii = "kitten ssh ivdi@ikiikiinu";
        hkk = "home-manager --impure switch --flake .#kawaiikuma";
        hnn = "home-manager --impure switch --flake .#nikoneko";
        hii = "home-manager --impure switch --flake .#ikiikiinu";
      };
    };

    home.packages = with pkgs; [ fish fortune cowsay ];
  };
}
