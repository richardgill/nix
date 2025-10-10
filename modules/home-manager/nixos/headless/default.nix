{
  lib,
  pkgs,
  vars,
  osConfig,
  ...
}:
{
  imports = [
    ../../shared/headless
    ./home.nix
  ];
}
