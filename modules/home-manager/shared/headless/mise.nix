{
  lib,
  pkgs,
  ...
}:
let
  template = import ../../../../utils/template.nix { inherit pkgs; };
in
{
  home.packages = with pkgs; [
    mise
  ];

  # Mise configuration file
  home.file.".config/mise/config.toml" = {
    text = builtins.readFile (
      template.renderMustache "mise-config" ../../dot-files/mise/config.toml.mustache {
        inherit (pkgs.stdenv) isLinux;
      }
    );
  };

  # Install mise tools after config is written
  # Node is very slow, so disable for now
  home.activation.miseInstall = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.mise}/bin/mise install
  '';
}
