{
  pkgs,
  lib,
  inputs,
  outputs,
  vars,
  ...
}:
{
  imports = [ inputs.determinate.nixosModules.default ];

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
    # User-level SOPS needs the user's runtime directory and systemd session.
    startAsUserService = true;
    extraSpecialArgs = {
      inherit inputs outputs vars;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
  };
}
