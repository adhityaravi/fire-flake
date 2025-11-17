# Just Recipe Modules

This directory contains modular justfile recipes that can be enabled per-profile.

## Structure

- `charm-dev.just` - Charm development recipes (juju, charmcraft, microk8s setup)
- Add more `.just` files here as needed

## Adding a New Recipe Module

1. Create a new `.just` file in this directory (e.g., `docker.just`)
2. Add the recipe option in `modules/home-manager/programs/just.nix`:
   ```nix
   recipes = {
     charm-dev = lib.mkEnableOption "Include charm development recipes";
     docker = lib.mkEnableOption "Include docker recipes";  # Add this
   };
   ```
3. Add the file to the concatenation list:
   ```nix
   globalJustfile = pkgs.writeText "justfile" (
     lib.concatStringsSep "\n\n" (
       lib.optionals cfg.recipes.charm-dev [(builtins.readFile ../../justfiles/charm-dev.just)]
       ++ lib.optionals cfg.recipes.docker [(builtins.readFile ../../justfiles/docker.just)]
     )
   );
   ```
4. Update the condition for installing the justfile:
   ```nix
   xdg.configFile."just/justfile" = lib.mkIf (
     cfg.recipes.charm-dev || cfg.recipes.docker
   ) {
   ```
5. Enable it in your profile (`profiles/users/default/home.nix`):
   ```nix
   custom.just = {
     enable = true;
     recipes = {
       charm-dev = true;
       docker = true;
     };
   };
   ```

## Usage

After rebuilding your home-manager configuration, you can run recipes globally:

```bash
just -g setup-charm-dev    # Run global justfile
just -g <recipe-name>       # Any recipe from enabled modules
```

Or without `-g` if you're in a directory without a local justfile.
