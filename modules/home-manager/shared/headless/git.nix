{ config, pkgs, ... }:

{
  home.file = {
    ".gitconfig".source = ../../dot-files/git/gitconfig;
    ".config/delta/themes.gitconfig".source = ../../dot-files/git/delta-themes.gitconfig;
  };
}