{ vars, ... }:
{
  homebrew.casks = [ "beeper" ];
  home-manager.users.${vars.userName}.imports = [
    ../../../home-manager/shared/headless/optional/beeper.nix
  ];
}
