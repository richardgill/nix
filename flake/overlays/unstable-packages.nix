{ inputs }:
# Share one nixpkgs-unstable evaluation instead of importing it independently in each consumer.
_final: prev: {
  unstablePkgs = import inputs.nixpkgs-unstable {
    inherit (prev.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
}
