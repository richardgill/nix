{
  inputs,
  outputs,
  vars,
  ...
}: {
  imports = [
    inputs.home-manager.darwinModules.home-manager
    inputs.sops-nix.darwinModules.sops
    inputs.stylix.darwinModules.stylix
    inputs.mac-app-util.darwinModules.default

    ./hardware-configuration.nix

    ./../../modules/system/mac/default.nix
  ];
  # needed with nix determinate package
  nix.enable = false;
  home-manager = {
    extraSpecialArgs = {inherit inputs outputs vars; nixpkgs-unstable = inputs.nixpkgs-unstable;};
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

  networking = {
    hostName = "mbp-m1";
    computerName = "mbp-m1";
    localHostName = "mbp-m1";
  };
}
