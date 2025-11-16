_:
{
  # Enable Avahi for .local hostname resolution
  services.avahi = {
    enable = true;
    nssmdns4 = true;

    # Opens UDP port 5353 for mDNS service discovery (required for printer detection)
    openFirewall = true;

    # Publish local services so other devices can discover this machine
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };
}
