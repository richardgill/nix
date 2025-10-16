{
  pkgs,
  lib,
  inputs,
  outputs,
  vars,
  ...
}:
{
  users.users.${vars.userName} = {
    isNormalUser = true;
    description = vars.fullName;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [ ];
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs vars;
      inherit (inputs) nixpkgs-unstable;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
  };
}
