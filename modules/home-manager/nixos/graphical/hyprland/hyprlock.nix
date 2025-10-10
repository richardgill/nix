{ pkgs, ... }:
{
  programs.hyprlock = {
    enable = true;

    package = pkgs.hyprlock;
  };

  xdg.configFile."hypr/hyprlock.conf".source = ./hyprlock.conf;
}
