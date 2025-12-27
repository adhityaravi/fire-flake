{ config, lib, pkgs, ... }:
let
  cfg = config.custom.k9s;

  # Wrapper for k9s that uses nss_wrapper to fake passwd entry for LDAP users
  k9s-ldap-wrapper = pkgs.writeShellScriptBin "k9s" ''
    export NSS_WRAPPER_PASSWD="$HOME/.k9s-passwd"
    export NSS_WRAPPER_GROUP="/etc/group"

    # Create fake passwd entry if it doesn't exist
    if [ ! -f "$NSS_WRAPPER_PASSWD" ]; then
      echo "$(id -un):x:$(id -u):$(id -g)::$HOME:/bin/sh" > "$NSS_WRAPPER_PASSWD"
    fi

    export LD_PRELOAD="${pkgs.nss_wrapper}/lib/libnss_wrapper.so"
    exec ${pkgs.k9s}/bin/k9s "$@"
  '';
in {
  options.custom.k9s = {
    enable = lib.mkEnableOption "Enable k9s.";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.k9s;
      description = "k9s package to install.";
    };

    ldapWorkaround = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use nss_wrapper to work around LDAP user lookup issues.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (if cfg.ldapWorkaround then k9s-ldap-wrapper else cfg.package)
    ];
  };
}
