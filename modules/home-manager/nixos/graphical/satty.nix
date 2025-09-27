{ config, lib, pkgs, ... }:

{
  xdg.configFile."satty/config.toml".source = ./satty/config.toml;

  home.file."Screenshots/.keep".text = "";
}
