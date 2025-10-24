{
  pkgs,
  lib,
  vars,
  ...
}:
{
  services.openssh.enable = true;

  users.users.${vars.userName}.openssh.authorizedKeys.keys = vars.sshAllPublicKeys;

  environment.systemPackages = with pkgs; [
    openssh
    sshfs
  ];
}
