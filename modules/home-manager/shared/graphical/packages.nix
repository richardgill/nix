{ config, lib, pkgs, nixpkgs-unstable, ... }:

let
  unstable = import nixpkgs-unstable { system = pkgs.system; config.allowUnfree = true; };
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
  isAarch64Linux = pkgs.system == "aarch64-linux";
in
{
  home.packages = with pkgs; [
    alacritty
    cmus
    mpv
    tmux
    vscode
  ] ++ lib.optionals (!isAarch64Linux) [
    slack
    spotify
    discord
    google-chrome
    zoom-us
  ] ++ lib.optionals (isLinux && !isAarch64Linux) [
    unstable._1password-gui
    unstable.code-cursor
  ];
}