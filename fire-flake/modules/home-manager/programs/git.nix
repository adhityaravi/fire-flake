{ config, lib, pkgs, ... }:

let
  cfg = config.custom.git;
in
{
  options.custom.git = {
    enable = lib.mkEnableOption "Enable Git configuration";

    userName = lib.mkOption {
      type = lib.types.str;
      description = "Git user name for commits.";
    };

    userEmail = lib.mkOption {
      type = lib.types.str;
      description = "Git user email for commits.";
    };

    signingKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional GPG signing key.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {
        init.defaultBranch = "main";
        pull.rebase = true;
        color.ui = "auto";
        push.autoSetupRemote = true;
        commit.gpgSign = false; # Will override below if signingKey provided
      };
      description = "Additional Git configuration attributes.";
    };

    aliases = lib.mkOption {
      type = lib.types.attrs;
      default = {
        co = "checkout";
        br = "branch";
        cm = "commit -m";
        st = "status";
        lg = "log --graph --oneline --decorate --all";
        last = "log -1 HEAD";
        amend = "commit --amend --no-edit";
        unstage = "reset HEAD --";
        undo = "reset --soft HEAD~1";
      };
      description = "Git command aliases.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;

      signing = lib.mkIf (cfg.signingKey != null) {
        key = cfg.signingKey;
        signByDefault = true;
      };

      settings = lib.mkMerge [
        {
          user = {
            name = cfg.userName;
            email = cfg.userEmail;
          };
          alias = cfg.aliases;
        }
        (lib.mkDefault cfg.extraConfig)
        cfg.extraConfig
      ];
    };
  };
}
