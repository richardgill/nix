{
  description = "nix-config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-firefox-151-stable.url = "github:nixos/nixpkgs/e820eb4a444b46a19b2e03e8dfd2359439ff30fe";

    gh-stack = {
      url = "github:github/gh-stack";
      flake = false;
    };

    # Pin until the clipboard clear deadlock fix is merged and released.
    # https://github.com/abenz1267/elephant/issues/282
    # https://github.com/abenz1267/elephant/commit/c9cc79b0b149f7f3045d6d2e27db00c52077a631
    elephant = {
      url = "github:abenz1267/elephant/c9cc79b0b149f7f3045d6d2e27db00c52077a631";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Use a commit SHA from https://github.com/nix-community/neovim-nightly-overlay/commits/master;
    # each commit pins a matching Neovim nightly source and build dependencies.
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay/4795f73d45458c015d1997ece7867d9341f0f6cd";

    impermanence.url = "github:nix-community/impermanence";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rex = {
      url = "https://pkgs.superlogical.com/rex/nix/preview.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
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

    homebrew-cone = {
      url = "github:conductorone/homebrew-cone";
      flake = false;
    };

    # Pin before Docker Desktop adopted cask syntax unsupported by Homebrew 6.0.13. Remove after nix-homebrew ships a newer Homebrew release.
    # https://github.com/Homebrew/homebrew-cask/commit/957be8614e7cb00871430075ad1876c857430f8b
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask/1d8e5d0dbc14e8c9d22be23abae5f79b11a9ef48";
      flake = false;
    };

    # Official Linux ChatGPT + Codex preview; nixpkgs currently packages ChatGPT only for macOS.
    # https://github.com/danielbodart/chatgpt-desktop
    chatgpt-desktop = {
      url = "github:danielbodart/chatgpt-desktop/81091718abffc59852bf6ccec7080203b9a0afab";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    xremap-flake.url = "github:xremap/nix-flake";

    stylix = {
      url = "github:danth/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # https://github.com/peteonrails/voxtype/pull/25
    voxtype = {
      url = "github:peteonrails/voxtype/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Playwright browsers for agent-browser/testing - pinned to match npm playwright version
    # https://github.com/pietdevries94/playwright-web-flake
    playwright = {
      url = "github:pietdevries94/playwright-web-flake/1.58.0";
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

      directoryNames =
        path:
        if builtins.pathExists path then
          builtins.attrNames (nixpkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir path))
        else
          [ ];

      discoverHosts =
        root: systemForDir:
        let
          getHosts =
            dir:
            let
              systemPath = root + "/${dir}";
            in
            nixpkgs.lib.genAttrs (directoryNames systemPath) (name: {
              system = systemForDir dir;
              path = systemPath + "/${name}/configuration.nix";
            });
          addHosts =
            hosts: dir:
            let
              newHosts = getHosts dir;
              duplicates = builtins.attrNames (builtins.intersectAttrs hosts newHosts);
            in
            if duplicates == [ ] then
              hosts // newHosts
            else
              throw "Duplicate host names under ${toString root}: ${builtins.concatStringsSep ", " duplicates}";
        in
        nixpkgs.lib.foldl' addHosts { } (directoryNames root);

      # Auto-discover machine configurations in the ./machines/ directory
      nixosHosts = discoverHosts ./machines/nixos (arch: "${arch}-linux");
      darwinHosts = discoverHosts ./machines/darwin (arch: "${arch}-darwin");
      homeManagerHosts = discoverHosts ./home-manager (system: system);

      mkNixOSConfig =
        hostName: path:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs vars;
            inherit hostName;
          };
          modules = [
            path
            {
              nixpkgs.overlays = [
                (import ./overlays/unstable-packages.nix { inherit inputs; })
                (import ./overlays/pins.nix { inherit inputs; })
                (import ./overlays/bambu-studio.nix)
              ];
            }
          ];
        };

      mkDarwinConfig =
        hostName: path:
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs outputs vars;
            inherit hostName;
          };
          modules = [
            path
            {
              nixpkgs.overlays = [
                (import ./overlays/unstable-packages.nix { inherit inputs; })
                (import ./overlays/pins.nix { inherit inputs; })
              ];
            }
          ];
        };

      mkHomeConfig =
        { system, path }:
        let
          inherit (import path) userName module;
        in
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              (import ./overlays/unstable-packages.nix { inherit inputs; })
              (import ./overlays/pins.nix { inherit inputs; })
            ];
          };
          extraSpecialArgs = {
            inherit inputs outputs;
            vars = vars // {
              inherit userName;
            };
          };
          modules = [ module ];
        };

    in
    {
      homeConfigurations = nixpkgs.lib.mapAttrs (_: mkHomeConfig) homeManagerHosts;

      ghStackSkill = "${inputs.gh-stack}/skills/gh-stack";

      # Enables `nix fmt` at root of repo to format all nix files
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      # for `nix flake check`
      checks = forAllSystems (
        system:
        {
          formatting = treefmtEval.${system}.config.build.check self;
        }
        // nixpkgs.lib.mapAttrs' (
          name: _: nixpkgs.lib.nameValuePair "home-${name}" self.homeConfigurations.${name}.activationPackage
        ) (nixpkgs.lib.filterAttrs (_: config: config.system == system) homeManagerHosts)
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

      # Export template config for manual template building
      # Usage: nix eval --json .#templateConfig.<machine> > config.json
      templateConfig =
        nixpkgs.lib.mapAttrs (
          name: nixosConfig:
          import ./utils/template-config.nix {
            inherit (nixpkgs) lib;
            inherit (nixosConfig) pkgs;
            config = nixosConfig.config.home-manager.users.${vars.userName};
          }
        ) self.nixosConfigurations
        // nixpkgs.lib.mapAttrs (
          name: homeConfig:
          import ./utils/template-config.nix {
            inherit (nixpkgs) lib;
            inherit (homeConfig) pkgs config;
          }
        ) self.homeConfigurations;
    };
}
