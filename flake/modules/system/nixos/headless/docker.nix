{ vars, ... }:
{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  users.users.${vars.userName}.extraGroups = [ "docker" ];
}
