{
  pkgs,
  lib,
  vars,
  ...
}:
{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      PubkeyAuthentication = true;
      MaxAuthTries = 3;
      ClientAliveInterval = 300;
      ClientAliveCountMax = 2;
    };
    openFirewall = true;
  };

  # SSH key management for users
  users.users.${vars.userName}.openssh.authorizedKeys.keys = [
    vars.sshPublicKeyPersonal
    vars.sshPublicKeyWork
  ];

  # Optional: Install useful SSH-related packages
  environment.systemPackages = with pkgs; [
    openssh
    sshfs
  ];

  # Optional: SSH agent service for GUI sessions
  programs.ssh.startAgent = lib.mkDefault false; # Let desktop environment handle it
}
