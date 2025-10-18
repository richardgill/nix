{
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
      device = "/dev/vda";
      resumeOffset = "533760";
      swapSize = "12G";
      isSsd = true;
    })
    ../../../../modules/system/nixos/common
    ../../../../modules/system/nixos/graphical
  ];

  home-manager.users.${vars.userName} = {
    imports = [
      ../../../../modules/home-manager/nixos/graphical
    ];
  };

}
