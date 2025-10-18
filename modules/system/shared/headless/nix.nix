{
  config,
  lib,
  pkgs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  nix = lib.mkMerge [
    # Only enable garbage collection when nix is enabled (Darwin with Determinate installer has nix.enable = false)
    (lib.mkIf (config.nix.enable or true) {
      gc = {
        automatic = true;
        options = "--delete-older-than 14d";
      }
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        interval = "weekly";
      }
      // lib.optionalAttrs pkgs.stdenv.isLinux {
        dates = "weekly";
      };
    })
    {
      settings = {
        experimental-features = "nix-command flakes";
        auto-optimise-store = true;
        download-buffer-size = 268435456;
        eval-cache = true;
        keep-derivations = true;
        keep-outputs = true;
        builders-use-substitutes = true;
        max-jobs = "auto";
        cores = 0; # use all available cores
        max-substitution-jobs = 128;
        substituters = [
          "https://cache.nixos.org/"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    }
  ];
}
