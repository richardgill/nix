{
  lib,
  pkgs,
  vars,
  ...
}:
{
  environment.persistence."/persistent".users.${vars.userName}.directories = [ ".config/spotify" ];

  home-manager.users.${vars.userName}.home.packages = lib.optionals (
    pkgs.stdenv.hostPlatform.system != "aarch64-linux"
  ) [ pkgs.spotify ];
}
