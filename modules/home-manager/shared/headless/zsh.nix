{
  pkgs,
  lib,
  ...
}:
let
  utils = import ../../../../utils { inherit pkgs; };

  zshrcFile = utils.renderMustache "zshrc" ../../dot-files/zsh/zshrc.mustache {
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
