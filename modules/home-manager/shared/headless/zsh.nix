{
  pkgs,
  lib,
  config,
  osConfig,
  vars,
  ...
}:
let
  # Import shared templates
  templates = import ./templates.nix { inherit lib pkgs config osConfig vars; };
  inherit (templates) builtTemplates;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Environment variables loaded from .zshenv (sourced on all shell invocations)
    envExtra = builtins.readFile "${builtTemplates}/zshenv/zshenv";

    # Source the built zshrc from Nix store
    initContent = lib.mkBefore (builtins.readFile "${builtTemplates}/zsh/zshrc");
  };
}
