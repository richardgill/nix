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

    ../../../../modules/system/mac/default.nix
    ../../../../modules/system/mac/optional/bambu-studio.nix
    ../../../../modules/system/shared/headless/optional/vpn.nix
  ];
  # needed with nix determinate package
  nix.enable = false;
  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs vars;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      ${vars.userName} = {
        imports = [
          ../../../../modules/home-manager/mac
          ../../../../modules/home-manager/shared/graphical/optional/gaming-emulators.nix
          ../../../../modules/home-manager/nixos/headless/optional/playwright.nix
        ];
      };
    };
  };

}
