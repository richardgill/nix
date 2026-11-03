{
  vars,
  ...
}:
{
  home-manager.users.${vars.userName}.imports = [
    ../../../../home-manager/shared/headless/optional/local-music.nix
  ];
}
