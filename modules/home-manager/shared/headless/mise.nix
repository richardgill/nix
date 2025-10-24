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
    # Make all nix-installed programs available (git, curl, etc needed by mise backends)
    export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:$PATH"
    # Initialize mise shims so npm/pipx backends can find their tools
    eval "$(${pkgs.mise}/bin/mise activate bash)"
    ${pkgs.mise}/bin/mise install
  '';
}
