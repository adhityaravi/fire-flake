{ config, lib, pkgs, ... }:

let
  cfg = config.custom.just;

  # Build the global justfile by concatenating enabled recipe files
  globalJustfile = pkgs.writeText "justfile" (
    lib.concatStringsSep "\n\n" (
      lib.optionals cfg.recipes.charm-dev [(builtins.readFile ../../../justfiles/charm-dev.just)]
      ++ lib.optionals cfg.recipes.tailscale [(builtins.readFile ../../../justfiles/tailscale.just)]
      ++ lib.optionals cfg.recipes.runner [(builtins.readFile ../../../justfiles/runner.just)]
    )
  );
in
{
  options.custom.just = {
    enable = lib.mkEnableOption "Enable just task runner";

    recipes = {
      charm-dev = lib.mkEnableOption "Include charm development recipes";
      tailscale = lib.mkEnableOption "Include tailscale service management recipes";
      runner = lib.mkEnableOption "Include GitHub Actions runner recipes";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      just
    ];

    # Install global justfile to ~/.config/just/justfile
    xdg.configFile."just/justfile" = lib.mkIf (
      cfg.recipes.charm-dev || cfg.recipes.tailscale || cfg.recipes.runner
    ) {
      source = globalJustfile;
    };
  };
}
