{
  lib,
  pkgs,
  vars,
  config,
  ...
}:
let
  utils = import ../../../../utils { inherit pkgs; };
  homeDir = config.home.homeDirectory;
in
{
  # Write tmux config directly with plugin paths
  home.file.".config/tmux/tmux.conf".text = builtins.readFile (
    utils.renderMustache "tmux.conf" ../../dot-files/tmux/tmux.conf.mustache {
      inherit (pkgs.stdenv) isDarwin;
      inherit (pkgs.stdenv) isLinux;
      prefix = if pkgs.stdenv.isLinux then "F12" else "§";
      defaultShell = "${pkgs.zsh}/bin/zsh";
      inherit homeDir;
      # Plugin paths for initialization
      catppuccinPlugin = "${pkgs.tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux";
      resurrectPlugin = "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux";
      continuumPlugin = "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux";
    }
  );
}
