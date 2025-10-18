{
  description = "nix-config";

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

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
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

      # Auto-discover machine configurations in the ./machines/ directory
      discoverHosts =
        platform:
        let
          osType = if platform == "darwin" then "darwin" else "linux";
          archDirs = builtins.readDir (./machines + "/${platform}");
          getHostsForArch =
            arch:
            let
              archPath = ./machines + "/${platform}/${arch}";
              hostDirs = builtins.readDir archPath;
              toHostConfig =
                name: _:
                nixpkgs.lib.nameValuePair name {
                  system = "${arch}-${osType}";
                  path = archPath + "/${name}/configuration.nix";
                };
            in
            nixpkgs.lib.mapAttrs' toHostConfig (
              nixpkgs.lib.filterAttrs (name: type: type == "directory") hostDirs
            );
        in
        nixpkgs.lib.foldl' (acc: arch: acc // (getHostsForArch arch)) { } (builtins.attrNames archDirs);

      nixosHosts = discoverHosts "nixos";
      darwinHosts = discoverHosts "darwin";

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
      checks = forAllSystems (
        system:
        {
          formatting = treefmtEval.${system}.config.build.check self;
        }
        // nixpkgs.lib.mapAttrs' (
          name: config:
          nixpkgs.lib.nameValuePair "nixos-${name}" (mkNixOSConfig name config.path)
          .config.system.build.toplevel
        ) (nixpkgs.lib.filterAttrs (name: config: config.system == system) nixosHosts)
        // nixpkgs.lib.mapAttrs' (
          name: config: nixpkgs.lib.nameValuePair "darwin-${name}" (mkDarwinConfig name config.path).system
        ) (nixpkgs.lib.filterAttrs (name: config: config.system == system) darwinHosts)
      );

      darwinConfigurations = nixpkgs.lib.mapAttrs (
        name: config: mkDarwinConfig name config.path
      ) darwinHosts;

      nixosConfigurations = nixpkgs.lib.mapAttrs (
        name: config: mkNixOSConfig name config.path
      ) nixosHosts;

      # Export vars for scripts to access
      inherit vars;
    };
}
