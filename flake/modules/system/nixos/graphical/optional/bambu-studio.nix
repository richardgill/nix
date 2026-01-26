{ pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    bambu-studio
  ];

  # Network ports for Bambu Studio
  # UDP 2021 for local network discovery
  # TCP 8883, 7071, 15001-15005 for printer communication
  # TCP 13618 for OAuth callback server (localhost login)
  networking.firewall = {
    allowedUDPPorts = [ 2021 ];
    allowedTCPPorts = [
      8883
      7071
      13618
    ] ++ (lib.range 15001 15005);
  };
}
