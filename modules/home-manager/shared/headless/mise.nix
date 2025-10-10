{
  lib,
  pkgs,
  nixpkgs-unstable,
  ...
}:
let
  unstable = import nixpkgs-unstable { inherit (pkgs) system; };
  utils = import ../../../../utils { inherit pkgs; };
in
{
  # Mise configuration file
  home.file.".config/mise/config.toml" = {
    text = builtins.readFile (
      utils.renderMustache "mise-config" ../../dot-files/mise/config.toml.mustache {
        inherit (pkgs.stdenv) isDarwin;
      }
    );
  };

  # Install mise tools after config is written
  # Node is very slow, so disable for now
  home.activation.miseInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${unstable.mise}/bin/mise install
  '';
}
