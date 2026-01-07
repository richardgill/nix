{ lib, ... }:
{
  # set default timeout to 10s - many times reboot waits 90s
  systemd.settings = {
    Manager = {
      DefaultTimeoutStopSec = "10s";
    };
  };
}
