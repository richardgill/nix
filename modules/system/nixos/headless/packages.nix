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
      psmisc
      pciutils # needed for lspci
      lm_sensors # fan sensors
    ]);
}
