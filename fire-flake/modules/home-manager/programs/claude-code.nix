{ config, lib, pkgs, ... }:
let
  cfg = config.custom.claudeCode;

  # Marketplace type definition
  marketplaceType = lib.types.submodule {
    options = {
      owner = lib.mkOption {
        type = lib.types.str;
        description = "GitHub owner/org of the marketplace repo.";
      };
      repo = lib.mkOption {
        type = lib.types.str;
        description = "GitHub repo name.";
      };
      rev = lib.mkOption {
        type = lib.types.str;
        description = "Git revision (commit hash, tag, or branch).";
      };
      hash = lib.mkOption {
        type = lib.types.str;
        description = "Nix hash of the fetched repo.";
      };
      plugins = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "List of plugin names to install and enable from this marketplace.";
      };
    };
  };

  # Fetch marketplace repos
  fetchedMarketplaces = lib.mapAttrs (name: mp:
    pkgs.fetchFromGitHub {
      owner = mp.owner;
      repo = mp.repo;
      rev = mp.rev;
      hash = mp.hash;
    }
  ) cfg.marketplaces;

  # Generate known_marketplaces.json content
  knownMarketplacesJson = builtins.toJSON (lib.mapAttrs (name: mp: {
    source = {
      source = "github";
      repo = "${mp.owner}/${mp.repo}";
    };
    installLocation = "${config.home.homeDirectory}/.claude/plugins/marketplaces/${name}";
    lastUpdated = "2025-01-01T00:00:00.000Z";
  }) cfg.marketplaces);

  # Generate installed_plugins.json content
  installedPluginsJson = builtins.toJSON {
    version = 1;
    plugins = lib.foldl' (acc: name:
      lib.foldl' (innerAcc: pluginName: innerAcc // {
        "${pluginName}@${name}" = {
          version = "unknown";
          installedAt = "2025-01-01T00:00:00.000Z";
          lastUpdated = "2025-01-01T00:00:00.000Z";
          installPath = "${config.home.homeDirectory}/.claude/plugins/marketplaces/${name}/plugins/${pluginName}";
          gitCommitSha = cfg.marketplaces.${name}.rev;
          isLocal = true;
        };
      }) acc cfg.marketplaces.${name}.plugins
    ) {} (builtins.attrNames cfg.marketplaces);
  };

  # Generate enabledPlugins for settings.json
  enabledPluginsFromMarketplaces = lib.foldl' (acc: name:
    lib.foldl' (innerAcc: pluginName: innerAcc // {
      "${pluginName}@${name}" = true;
    }) acc cfg.marketplaces.${name}.plugins
  ) {} (builtins.attrNames cfg.marketplaces);

  # Merge settings with enabled plugins
  finalSettings = cfg.settings // {
    enabledPlugins = (cfg.settings.enabledPlugins or {}) // enabledPluginsFromMarketplaces;
  };

in {
  options.custom.claudeCode = {
    enable = lib.mkEnableOption "Enable Claude Code CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.claude-code;
      description = "Claude Code package to install.";
    };

    extraEnv = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Additional environment variables for Claude Code.";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Global settings for Claude Code (written to ~/.claude/settings.json).";
    };

    marketplaces = lib.mkOption {
      type = lib.types.attrsOf marketplaceType;
      default = {};
      description = "Claude Code plugin marketplaces to install.";
      example = lib.literalExpression ''
        {
          claude-code-workflows = {
            owner = "wshobson";
            repo = "agents";
            rev = "c7ad381360bb8a2263aa42e25f81dc41161bf7d9";
            hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
            plugins = [ "python-development" "kubernetes-operations" ];
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.sessionVariables = cfg.extraEnv;

    home.file = lib.mkMerge [
      # Settings file
      (lib.mkIf (finalSettings != {} && finalSettings != { enabledPlugins = {}; }) {
        ".claude/settings.json".text = builtins.toJSON finalSettings;
      })

      # Plugin config files
      (lib.mkIf (cfg.marketplaces != {}) {
        ".claude/plugins/known_marketplaces.json".text = knownMarketplacesJson;
        ".claude/plugins/installed_plugins.json".text = installedPluginsJson;
        ".claude/plugins/config.json".text = builtins.toJSON { version = 1; };
      })

      # Marketplace repos (symlinked)
      (lib.mapAttrs' (name: _: lib.nameValuePair
        ".claude/plugins/marketplaces/${name}"
        { source = fetchedMarketplaces.${name}; }
      ) cfg.marketplaces)
    ];
  };
}
