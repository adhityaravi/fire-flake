{ config, lib, pkgs, ... }:

let
  cfg = config.custom.fish;

in {
  options.custom.fish = {
    enable = lib.mkEnableOption "Enable fish shell";
    setDefault = lib.mkEnableOption "Launch fish from bashrc (for LDAP users who can't use chsh)";
  };

  config = lib.mkIf cfg.enable {
    # Launch fish from bash for LDAP users (both login and interactive shells)
    programs.bash = lib.mkIf cfg.setDefault {
      enable = true;
      profileExtra = ''
        if [ -x "$HOME/.nix-profile/bin/fish" ]; then
          exec "$HOME/.nix-profile/bin/fish" -l
        fi
      '';
    };
    programs.fish = {
      enable = true;
      loginShellInit = ''
        # Add nix paths for login shells (needed when fish is default shell)
        fish_add_path --prepend ~/.nix-profile/bin /nix/var/nix/profiles/default/bin
      '';
      interactiveShellInit = ''
        set -g fish_greeting ""
        set -gx KUBECONFIG ~/.kube/config
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
      functions = {
        w = "curl -s wttr.in/$argv[1]";
      };
    };

    home.packages = with pkgs; [ fish fortune cowsay ];
  };
}
