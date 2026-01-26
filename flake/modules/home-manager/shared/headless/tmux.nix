{
  lib,
  pkgs,
  vars,
  config,
  osConfig,
  ...
}:
let
  # Import the shared templates builder
  templates = import ./templates.nix { inherit lib pkgs config osConfig vars; };
in
{
  home.file.".config/tmux/tmux.conf".source = "${templates.builtTemplates}/tmux/tmux.conf";
}
