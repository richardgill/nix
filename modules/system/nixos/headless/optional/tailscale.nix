{ config, ... }:
{
  # After enabling, authenticate with: sudo tailscale up --accept-dns=false
  # Get auth keys at: https://login.tailscale.com/admin/settings/keys
  # --accept-dns=false prevents Tailscale's MagicDNS from overriding local DNS,
  # allowing NetworkManager to use DNS servers from DHCP (router) for public domain resolution
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "both";
  };

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
}
