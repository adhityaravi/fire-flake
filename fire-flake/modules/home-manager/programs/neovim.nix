{ config, pkgs, lib, nurpkgs ? {}, ... }:

let
  cfg = config.custom.neovim;
  pluginList = (import ./neovim/plugins.nix { inherit pkgs nurpkgs; });
in
{
  options.custom.neovim = {
    enable = lib.mkEnableOption "Enable custom Neovim";
    extraPlugins = lib.mkOption {
      type = with lib.types; listOf package;
      default = [];
      description = "Extra Neovim plugins to install.";
    };
    extraLuaConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra Lua config to be injected after core setup.";
    };
  };

  config = lib.mkIf cfg.enable {
    fonts.fontconfig.enable = true;

    # copy lua configs
    xdg.configFile."nvim/lua".source = ./neovim/lua;

    programs.neovim = {
      enable = true;
      vimAlias = true;
      viAlias = true;
      vimdiffAlias = true;
      withNodeJs = true;
      extraPackages = with pkgs; [
        pyright
        gopls
        terraform-ls
        nixd
        nodePackages.bash-language-server
        nodePackages.vscode-langservers-extracted
        nodePackages.dockerfile-language-server-nodejs
        nodePackages.yaml-language-server
        lua-language-server
      ];
      plugins = pluginList ++ cfg.extraPlugins;
      extraLuaConfig = let
        workspacesLua = builtins.concatStringsSep "\n" (
          map (path: "  { name = \"" + (builtins.baseNameOf path) + "\", path = \"" + path + "\" },")
            config.custom.obsidian.vaultPaths
        );
      in ''
        vim.g.fireflake_obsidian_workspaces = {
${workspacesLua}
        }

        ${builtins.readFile ./neovim/lua/init.lua}
        ${cfg.extraLuaConfig}
      '';
    };
  };
}
