{
  lib,
  pkgs,
  nixpkgs-unstable,
  ...
}:
let
  template = import ../../../../utils/template.nix { inherit pkgs; };
  unstable = import nixpkgs-unstable {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
in
{
  # we use unstable to get slightly more up-to-date deps
  home.packages = [
    unstable.mise
  ];

  home.sessionVariables = {
    MISE_NODE_COREPACK = "true";
  };

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
    export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/usr/bin:/bin:$PATH"
    # Initialize mise shims so npm/pipx backends can find their tools
    eval "$(${unstable.mise}/bin/mise activate bash)"
    ${unstable.mise}/bin/mise install
  '';
}
