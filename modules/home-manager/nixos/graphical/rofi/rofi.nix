{ pkgs, lib, ... }:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    terminal = "ghostty";
  };

  xdg.configFile."rofi/config.rasi".text = builtins.readFile ./config.rasi;
}
