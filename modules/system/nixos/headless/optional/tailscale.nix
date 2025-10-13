{ config, ... }:
{
  # After enabling, authenticate with: sudo tailscale up
  # Get auth keys at: https://login.tailscale.com/admin/settings/keys
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
