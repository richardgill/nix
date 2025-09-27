{ config, pkgs, lib, osConfig, ... }:

{
  stylix = {
    enable = lib.mkDefault (osConfig.stylix.enable or false);
    autoEnable = lib.mkDefault true;

    targets = {
      firefox.profileNames = [ "default" ];
    };
  };
}
