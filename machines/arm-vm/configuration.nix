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
    ../../modules/system/nixos/graphical
  ];

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs vars;
      inherit (inputs) nixpkgs-unstable;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      ${vars.userName} = {
        imports = [
          ./../../modules/home-manager/nixos/graphical
        ];
      };
    };
  };

}
