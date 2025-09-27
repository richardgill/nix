{
  description = "rich-nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    impermanence.url = "github:nix-community/impermanence";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixarr = {
      url = "github:rasmus-kirk/nixarr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    xremap-flake.url = "github:xremap/nix-flake";

    hyprpaper = {
      url = "github:hyprwm/hyprpaper";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util = {
      url = "github:hraban/mac-app-util";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      vars = import ./vars.nix;
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkNixOSConfig =
        hostName: path:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs vars;
            nixpkgs-unstable = inputs.nixpkgs-unstable;
            hostName = hostName;
          };
          modules = [ path ];
        };

      mkDarwinConfig =
        path:
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs outputs vars;
            nixpkgs-unstable = inputs.nixpkgs-unstable;
          };
          modules = [ path ];
        };
    in
    {
      # Enables `nix fmt` at root of repo to format all nix files
      # todo: change this
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

      darwinConfigurations = {
        mbp-m1 = mkDarwinConfig ./machines/mbp-m1/configuration.nix;
      };

      nixosConfigurations = {
        beelink-zoe = mkNixOSConfig "beelink-zoe" ./machines/beelink-zoe/configuration.nix;
        arm-vm = mkNixOSConfig "arm-vm" ./machines/arm-vm/configuration.nix;
        x86-vm = mkNixOSConfig "x86-vm" ./machines/x86-vm/configuration.nix;
      };

      # Export vars for scripts to access
      inherit vars;
    };
}
