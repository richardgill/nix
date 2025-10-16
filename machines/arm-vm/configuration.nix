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
    ./disko.nix
    ../../modules/system/nixos/common
    ../../modules/system/nixos/graphical
  ];

  home-manager.users.${vars.userName} = {
    imports = [
      ./../../modules/home-manager/nixos/graphical
    ];
  };

}
