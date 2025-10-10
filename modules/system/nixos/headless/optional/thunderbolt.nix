{ pkgs, ... }:
{
  services.hardware.bolt.enable = true;

  # Systemd service to auto-enroll specific devices
  systemd.services.enroll-thunderbolt-devices = {
    description = "Enroll Thunderbolt devices";
    after = [ "bolt.service" ];
    wants = [ "bolt.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = pkgs.writeScript "enroll-thunderbolt-devices" ''
        #!${pkgs.bash}/bin/bash
        sleep 30  # Wait for device detection
        ${pkgs.bolt}/bin/boltctl enroll --chain 36a78780-0028-6180-ffff-ffffffffffff || exit 0
      '';
    };
  };
}
