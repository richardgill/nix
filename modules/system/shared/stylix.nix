{
  pkgs,
  lib,
  ...
}:
{
  stylix = {
    enable = true;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";

    polarity = "dark";

    image = ../../../assets/wallpapers/tokyo-night-abstract.jpg;

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.hack;
        name = "Hack Nerd Font";
      };

      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };

      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };

      sizes = {
        applications = lib.mkDefault 11;
        terminal = lib.mkDefault 12;
        desktop = lib.mkDefault 10;
        popups = lib.mkDefault 10;
      };
    };

    opacity = {
      applications = 1.0;
      terminal = 0.95;
      desktop = 1.0;
      popups = 0.95;
    };

    autoEnable = true;
  };
}
