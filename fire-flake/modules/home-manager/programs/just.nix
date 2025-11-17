{ config, lib, pkgs, ... }:

let
  cfg = config.custom.just;

  # Build the global justfile by concatenating enabled recipe files
  globalJustfile = pkgs.writeText "justfile" (
    lib.concatStringsSep "\n\n" (
      lib.optionals cfg.recipes.charm-dev [(builtins.readFile ../../../justfiles/charm-dev.just)]
      # Add more recipe files here as they're enabled
    )
  );
in
{
  options.custom.just = {
    enable = lib.mkEnableOption "Enable just task runner";

    recipes = {
      charm-dev = lib.mkEnableOption "Include charm development recipes";
      # Add more recipe options here as needed
      # docker = lib.mkEnableOption "Include docker recipes";
      # kubernetes = lib.mkEnableOption "Include kubernetes recipes";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      just
    ];

    # Install global justfile to ~/.config/just/justfile
    xdg.configFile."just/justfile" = lib.mkIf (
      cfg.recipes.charm-dev
      # Add more conditions here: || cfg.recipes.docker || cfg.recipes.kubernetes
    ) {
      source = globalJustfile;
    };
  };
}
