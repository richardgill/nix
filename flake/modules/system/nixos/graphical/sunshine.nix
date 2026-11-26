{ config, lib, ... }:
{
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    openFirewall = true;
    settings = {
      csrf_allowed_origins = "https://${config.networking.hostName}:47990";
      # Use Niri's native capture instead of hanging in the portal when no monitor is connected.
      capture = "wlr";
    };
  };

  systemd.user.services.sunshine.serviceConfig.Restart = lib.mkForce "always";
}
