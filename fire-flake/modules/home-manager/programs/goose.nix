{ config, lib, pkgs, ... }:

let
  cfg = config.custom.goose;
  envVars = lib.filterAttrs (n: v: v != null) {
    # GOOSE_PROVIDER = cfg.provider;
    # GOOSE_MODEL = cfg.model;
    # GOOSE_LEAD_MODEL = cfg.leadModel;
    # GOOSE_LEAD_PROVIDER = cfg.leadProvider;
    # GOOSE_PLANNER_MODEL = cfg.plannerModel;
    # GOOSE_PLANNER_PROVIDER = cfg.plannerProvider;
  };
in
{
  options.custom.goose = {
    enable = lib.mkEnableOption "Enable goose CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.goose-cli;
      description = "Goose CLI package to install.";
    };

    provider = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Default LLM provider (GOOSE_PROVIDER).";
    };

    model = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Default LLM model (GOOSE_MODEL).";
    };

    leadModel = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Lead model for lead/worker mode (GOOSE_LEAD_MODEL).";
    };

    leadProvider = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Provider for lead model (GOOSE_LEAD_PROVIDER).";
    };

    plannerModel = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Model to use for planning (GOOSE_PLANNER_MODEL).";
    };

    plannerProvider = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Provider for planning model (GOOSE_PLANNER_PROVIDER).";
    };

    extraEnv = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Additional environment variables for goose.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.sessionVariables = envVars // cfg.extraEnv;
  };
}
