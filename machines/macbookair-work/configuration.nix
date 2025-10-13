{
  inputs,
  outputs,
  vars,
  ...
}:
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.stylix.darwinModules.stylix

    ./hardware-configuration.nix

    ./../../modules/system/mac/default.nix
  ];
  # needed with nix determinate package
  nix.enable = false;
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
          ./../../modules/home-manager/mac
        ];
      };
    };
  };

}
