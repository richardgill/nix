{ pkgs, vars, ... }:
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    package = pkgs.docker_29;
  };

  users.users.${vars.userName}.extraGroups = [ "docker" ];
}
