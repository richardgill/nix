{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
let
  # Import the shared templates builder
  templates = import ./templates.nix {
    inherit
      lib
      pkgs
      config
      inputs
      ;
  };
in
{
  home.packages = [ pkgs.tmux ];

  home.file.".config/tmux/tmux.conf".source = "${templates.builtTemplates}/tmux/tmux.conf";
}
