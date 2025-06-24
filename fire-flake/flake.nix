{
  description = "A flake that sets up a fire system configuration 🔥";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nurpkgs = {
      url = "github:adhityaravi/nurpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Optional: if disabled, an attempt will be made to load local configuration file from the vars directory. 
    # Note: Only ssh auth is tested.
    fire-flake-config = {
      url = "git+ssh://git@github.com/adhityaravi/fire-flake-config-ivdi.git";
      flake = true;
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: 

  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
        inherit system;
        overlays = [ (import "${inputs.nurpkgs}/overlay.nix") ];
        # allow codeium, copilot, windsurf and obsidian unfree packages
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "codeium" "copilot" "windsurf" "obsidian" "claude-code"];
    };

    nurpkgs = inputs.nurpkgs.packages.${system};

    fireFlakeConfig = if inputs ? fire-flake-config && inputs.fire-flake-config ? fireFlakeConfig then
      inputs.fire-flake-config.fireFlakeConfig
    else
      null;

    # Load user variables
    userVars = import ./lib/loadVars.nix {
      inherit (nixpkgs) lib;
      fireFlakeConfig = fireFlakeConfig;
    };

  in
  {
    #TODO: add a dev shell or homeconfig for charm-dev?

    # Dev shells
    devShells.${system} = {
      default = import ./dev-shells/default.nix { inherit pkgs; };
    };

    homeConfigurations = {
      # Default home-manager configuration
      default = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ./profiles/users/default/home.nix
        ];

        extraSpecialArgs = {
          inherit userVars nurpkgs;
        };
      };  
    };
  };
}
