{ config, lib, pkgs, ... }:

{
  xdg.configFile."swayosd/style.css".source = ./swayosd/style.css;
}