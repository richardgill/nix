{
  services.eternal-terminal = {
    enable = true;
    port = 2022;
  };

  networking.firewall.allowedTCPPorts = [ 2022 ];
}
