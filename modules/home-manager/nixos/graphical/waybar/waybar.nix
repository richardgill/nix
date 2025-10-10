{
  config,
  lib,
  pkgs,
  ...
}:
let
  waybarConfig = builtins.fromJSON (builtins.readFile ./config.jsonc);
in
{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = waybarConfig;
    };
    style = builtins.readFile ./style.css;
  };

  home.file = {
    ".config/waybar/power_menu.xml".source = ./power_menu.xml;
  };
}
