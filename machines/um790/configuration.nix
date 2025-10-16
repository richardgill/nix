{
  pkgs,
  lib,
  vars,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/system/nixos/common
    ../../modules/system/nixos/graphical
    ../../modules/system/nixos/graphical/optional/bluetooth.nix
    ../../modules/system/nixos/graphical/optional/fingerprint.nix
    ../../modules/system/nixos/graphical/optional/wifi.nix
    ../../modules/system/nixos/headless/optional/btrbk.nix
    ../../modules/system/nixos/headless/optional/dev-ports.nix
    ../../modules/system/nixos/headless/optional/syncthing.nix
    ../../modules/system/nixos/headless/optional/tailscale.nix
    ../../modules/system/nixos/headless/optional/thunderbolt.nix
  ];

  # Faster boot loader
  boot.loader.timeout = lib.mkForce 3;

  # specific UM790 fix to prevent reboots when running idle
  # https://wiki.archlinux.org/title/Ryzen#Freeze_on_shutdown,_reboot_and_suspend
  boot.kernelParams = [
    "processor.max_cstate=1"
    "idle=nowait"
  ];

  # WiFi/Bluetooth firmware support for UM790
  hardware.firmware = with pkgs; [
    linux-firmware
  ];

  home-manager.users.${vars.userName} = {
    imports = [
      ./../../modules/home-manager/nixos/graphical
    ];
  };

  # Don't use thunderbolt ethernet
  networking.networkmanager.unmanaged = [ "enp195s0" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
