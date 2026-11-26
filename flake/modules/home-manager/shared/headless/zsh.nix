{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  # Import shared templates
  templates = import ./templates.nix {
    inherit
      lib
      pkgs
      config
      inputs
      ;
  };
  inherit (templates) builtTemplates;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # Initialize completion before custom shell setup: argc completions require compdef.
    completionInit = ''
      # Cache zsh completions and skip compaudit to speed startup
      mkdir -p "$HOME/.cache/zsh"
      autoload -U compinit
      compinit -C -d "$HOME/.cache/zsh/zcompdump"
    '';
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Environment variables loaded from .zshenv (sourced on all shell invocations)
    envExtra = builtins.readFile "${builtTemplates}/zshenv/zshenv";

    # Source the built zshrc from Nix store
    initContent = builtins.readFile "${builtTemplates}/zsh/zshrc";
  };
}
