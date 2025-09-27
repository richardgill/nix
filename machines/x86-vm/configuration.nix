{
  inputs,
  outputs,
  vars,
  hostName,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/system/nixos/graphical
  ];

  home-manager = {
    extraSpecialArgs = {inherit inputs outputs vars; nixpkgs-unstable = inputs.nixpkgs-unstable;};
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users = {
      ${vars.userName} = {
        imports = [
          ./../../modules/home-manager/nixos/graphical
        ];
      };
    };
  };

  networking.hostName = hostName;
}
