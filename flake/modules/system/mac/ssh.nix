{
  lib,
  pkgs,
  ...
}:
{
  services.openssh.enable = lib.mkDefault false;

  environment.systemPackages = with pkgs; [
    openssh
    sshfs
  ];
}
