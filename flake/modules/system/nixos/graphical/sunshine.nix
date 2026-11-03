{ config, lib, ... }:
{
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    openFirewall = true;
    settings.csrf_allowed_origins = "https://${config.networking.hostName}:47990";
  };

  systemd.user.services.sunshine.serviceConfig.Restart = lib.mkForce "always";
}
