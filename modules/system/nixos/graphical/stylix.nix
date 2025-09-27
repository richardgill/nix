{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    inputs.stylix.nixosModules.stylix
    ../../shared/stylix.nix
  ];

  stylix = {
    # Cursor theme - keeping the original macOS cursor
    cursor = {
      package = pkgs.apple-cursor;
      name = "macOS";
      size = 32;
    };
  };
}
