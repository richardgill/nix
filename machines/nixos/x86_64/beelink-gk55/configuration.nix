{
  pkgs,
  lib,
  inputs,
  outputs,
  vars,
  hostName,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    (import ../../../../modules/system/nixos/headless/disko.nix {
      device = "/dev/sda";
      resumeOffset = "533760";
      swapSize = "12G";
      isSsd = true;
    })
    ../../../../modules/system/nixos/common
    ../../../../modules/system/nixos/graphical
    ../../../../modules/system/nixos/graphical/optional/bluetooth.nix
    ../../../../modules/system/nixos/graphical/optional/fingerprint.nix
    ../../../../modules/system/nixos/graphical/optional/wifi.nix
    ../../../../modules/system/nixos/headless/optional/btrbk.nix
  ];

  home-manager.users.${vars.userName} = {
    imports = [
      ../../../../modules/home-manager/nixos/graphical
    ];
  };

  # Faster boot for mini PC
  boot.loader.timeout = lib.mkForce 3;

  # Enhanced graphics drivers for Intel J4125 UHD Graphics 600
  # VAAPI recommended over QSV for J4125
  # Reference: https://github.com/blakeblackshear/frigate/discussions/1382
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver
      intel-media-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # WiFi/Bluetooth firmware support for gk55
  hardware.firmware = with pkgs; [
    linux-firmware
  ];

  # Power management for efficient J4125 operation
  # Reference: https://github.com/MatthiasBenaets/nix-config/blob/master/hosts/beelink/hardware-configuration.nix
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  # networking.firewall.allowedUDPPorts = [ ... ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
