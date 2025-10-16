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

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      treefmt-nix,
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

      treefmtEval = forAllSystems (
        system: treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix
      );

      mkNixOSConfig =
        hostName: path:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs vars;
            inherit (inputs) nixpkgs-unstable;
            inherit hostName;
          };
          modules = [ path ];
        };

      mkDarwinConfig =
        hostName: path:
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs outputs vars;
            inherit (inputs) nixpkgs-unstable;
            inherit hostName;
          };
          modules = [ path ];
        };
    in
    {
      # Enables `nix fmt` at root of repo to format all nix files
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      # for `nix flake check`
      checks = forAllSystems (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });

      darwinConfigurations = {
        macbookair-work = mkDarwinConfig "macbookair-work" ./machines/macbookair-work/configuration.nix;
      };

      nixosConfigurations = {
        beelink-gk55 = mkNixOSConfig "beelink-gk55" ./machines/beelink-gk55/configuration.nix;
        um790 = mkNixOSConfig "um790" ./machines/um790/configuration.nix;
        arm-vm = mkNixOSConfig "arm-vm" ./machines/arm-vm/configuration.nix;
        x86-vm = mkNixOSConfig "x86-vm" ./machines/x86-vm/configuration.nix;
      };

      # Export vars for scripts to access
      inherit vars;
    };
}
