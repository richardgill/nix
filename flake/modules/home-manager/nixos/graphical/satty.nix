{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg.configFile."satty/config.toml".source = ./satty/config.toml;
}
