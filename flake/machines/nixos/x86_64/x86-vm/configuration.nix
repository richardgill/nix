{
  vars,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    (import ../../../../modules/system/nixos/headless/disko.nix {
      device = "/dev/sda";
      resumeOffset = "533760";
      swapSize = "10G";
      isSsd = true;
    })
    ../../../../modules/system/nixos/common
    ../../../../modules/system/nixos/graphical
    ../../../../modules/system/nixos/headless/optional/btrbk.nix
    ../../../../modules/system/nixos/headless/optional/dev-ports.nix
    ../../../../modules/system/nixos/headless/optional/remote-unlock.nix
  ];
  home-manager.users.${vars.userName} = {
    imports = [
      ../../../../modules/home-manager/nixos/graphical
    ];
  };

  # VM-specific: enable Mesa drivers for virtio-gpu
  hardware.graphics.enable = true;

  # environment.sessionVariables = {
  #   WLR_NO_HARDWARE_CURSORS = "1";
  #   LIBGL_ALWAYS_SOFTWARE = "1";
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
