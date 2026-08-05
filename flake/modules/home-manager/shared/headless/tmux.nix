{
  lib,
  pkgs,
  vars,
  config,
  osConfig,
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
      osConfig
      vars
      inputs
      ;
  };
in
{
  home.file.".config/tmux/tmux.conf".source = "${templates.builtTemplates}/tmux/tmux.conf";
}
