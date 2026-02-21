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
        dockerfile-language-server
        nodePackages.yaml-language-server
        lua-language-server
      ];
      plugins = pluginList ++ cfg.extraPlugins;
      initLua = ''
        ${builtins.readFile ./neovim/lua/init.lua}
        ${cfg.extraLuaConfig}
      '';
    };
  };
}
