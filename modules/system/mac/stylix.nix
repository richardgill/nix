{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ../shared/stylix.nix
  ];

  stylix = {
    # Darwin-specific font size overrides
    fonts.sizes = {
      applications = 12;
      terminal = 13;
      desktop = 11;
      popups = 11;
    };
  };
}