{
  pkgs,
  ...
}:
{
  # services.hypridle = {
  #   enable = true;
  #
  #   package = pkgs.hypridle;
  # };

  xdg.configFile."hypr/hypridle.conf".source = ./hypridle.conf;
}
