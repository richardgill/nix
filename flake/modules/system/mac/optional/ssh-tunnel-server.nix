{ pkgs, vars, ... }:
let
  authorizedKeys = pkgs.writeText "ssh-tunnel-authorized-keys" ''
    ${vars.sshPublicKeyMacbookAirWork}
  '';
  sshdConfig = pkgs.writeText "sshd-tunnel-config" ''
    AddressFamily inet
    ListenAddress 127.0.0.1
    Port 22
    HostKey /etc/ssh/ssh_host_ed25519_key
    PidFile /var/run/sshd-tunnel.pid
    AllowUsers ${vars.userName}
    AuthorizedKeysFile ${authorizedKeys}
    AuthorizedKeysCommand none
    AuthenticationMethods publickey
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    PermitRootLogin no
    UsePAM yes
    DisableForwarding yes
    Subsystem sftp internal-sftp
  '';
in
{
  # Apple's socket-activated SSH service listens on all interfaces, regardless of ListenAddress.
  services.openssh.enable = false;

  launchd.daemons.ssh-tunnel.serviceConfig = {
    ProgramArguments = [
      "/usr/sbin/sshd"
      "-D"
      "-e"
      "-f"
      "${sshdConfig}"
    ];
    RunAtLoad = true;
    KeepAlive = true;
    StandardErrorPath = "/var/log/sshd-tunnel.log";
  };
}
