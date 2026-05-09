final: prev:
let
  # Pin mise to a nixpkgs commit that ships 2026.4.20 (prebuilt in cache).
  # Bump rev to pull a newer mise; keep the rest of nixpkgs-unstable untouched.
  nixpkgsForMise = import (prev.fetchFromGitHub {
    owner = "nixos";
    repo = "nixpkgs";
    rev = "68a8af93ff4297686cb68880845e61e5e2e41d92";
    hash = "sha256-pYEytCNic/czazbV9r3tbQ6BZzqRBg/41x2dIC5ymOo=";
  }) {
    inherit (prev.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in {
  mise = nixpkgsForMise.mise;
}
