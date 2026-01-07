{
  config,
  lib,
  pkgs,
  ...
}:
let
  sharedPackages = import ../../shared/headless/packages.nix { inherit pkgs; };
in
{
  environment.systemPackages =
    sharedPackages.packages
    ++ (with pkgs; [
      lsof
      psmisc
      pciutils # needed for lspci
      lm_sensors # fan sensors
      sbctl # secure boot utils
    ]);
}
