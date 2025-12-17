{
  lib,
  pkgs,
  nixpkgs-unstable,
  config,
  osConfig,
  vars,
  ...
}:
let
  unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  # Import shared templates
  templates = import ./templates.nix { inherit lib pkgs config osConfig vars; };
  inherit (templates) builtTemplates;
in
{
  # we use unstable to get slightly more up-to-date deps
  home.packages = [
    unstable.mise
  ];

  home.sessionVariables = {
    MISE_NODE_COREPACK = "true";
  };

  # Mise configuration file (from built templates in Nix store)
  home.file.".config/mise/config.toml".source = "${builtTemplates}/mise/config.toml";

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
