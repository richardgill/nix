{
  pkgs,
  lib,
  ...
}:
let
  template = import ../../../../utils/template.nix { inherit pkgs; };

  zshrcFile = template.renderMustache "zshrc" ../../dot-files/zsh/zshrc.mustache {
    inherit (pkgs.stdenv) isDarwin;
  };
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = lib.mkBefore (builtins.readFile zshrcFile);
  };
}
