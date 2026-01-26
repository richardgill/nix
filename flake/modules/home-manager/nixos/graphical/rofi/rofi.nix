{
  pkgs,
  lib,
  ...
}:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    terminal = "ghostty";
  };

  xdg.configFile."rofi/config.rasi".text = builtins.readFile ./config.rasi;
}
