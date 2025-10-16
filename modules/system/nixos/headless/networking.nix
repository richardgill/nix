{ pkgs, hostName, ... }:
{
  networking = {
    inherit hostName;
    hostFiles = [ ];
    networkmanager.enable = true;
    firewall.enable = true;
  };
  # Remember to assign static map on edge router x and add a 'local dns record' in pihole
  # inspo: https://github.com/NixOS/nixpkgs/issues/180175#issuecomment-1658731959
  systemd.services.NetworkManager-wait-online = {
    serviceConfig = {
      ExecStart = [
        ""
        "${pkgs.networkmanager}/bin/nm-online -q"
      ];
    };
  };
}
