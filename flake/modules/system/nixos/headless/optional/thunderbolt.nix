{ pkgs, ... }:
{
  services.hardware.bolt.enable = true;

  # Systemd service to auto-enroll specific devices
  systemd.services.enroll-thunderbolt-devices = {
    description = "Enroll Thunderbolt devices";
    after = [ "bolt.service" ];
    wants = [ "bolt.service" ];
    wantedBy = [ "multi-user.target" ];
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      # prevent this from attempting to restart on `just switch` which was very slow
      ExecCondition = pkgs.writeScript "enroll-thunderbolt-devices-condition" ''
        #!${pkgs.bash}/bin/bash
        booted=$(readlink -f /run/booted-system 2>/dev/null || true)
        current=$(readlink -f /run/current-system 2>/dev/null || true)
        [ -n "$booted" ] && [ -n "$current" ] && [ "$booted" = "$current" ]
      '';
      ExecStart = pkgs.writeScript "enroll-thunderbolt-devices" ''
        #!${pkgs.bash}/bin/bash
        sleep 30  # Wait for device detection
        ${pkgs.bolt}/bin/boltctl enroll --chain 36a78780-0028-6180-ffff-ffffffffffff || exit 0
      '';
    };
  };
}
