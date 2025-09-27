{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Enable Avahi for .local hostname resolution
  services.avahi = {
    nssmdns4 = true;
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
