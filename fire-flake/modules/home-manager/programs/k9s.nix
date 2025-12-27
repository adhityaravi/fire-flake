{ config, lib, pkgs, ... }:
let
  cfg = config.custom.k9s;

  # k9s with CGO enabled for LDAP/NSS user lookup support
  k9s-cgo = pkgs.k9s.overrideAttrs (old: {
    env = (old.env or { }) // {
      CGO_ENABLED = "1";
    };
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.glibc ];
  });
in {
  options.custom.k9s = {
    enable = lib.mkEnableOption "Enable k9s.";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.k9s;
      description = "k9s package to install.";
    };

    enableCgo = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Build k9s with CGO enabled for LDAP/NSS user lookup support.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ (if cfg.enableCgo then k9s-cgo else cfg.package) ];
  };
}
