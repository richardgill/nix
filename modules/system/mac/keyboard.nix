{ pkgs, ... }:
let
  monitorScript = pkgs.writeShellScript "qmk-keyboard-monitor" ''
    export PATH="${pkgs.coreutils}/bin:/run/current-system/sw/bin:/usr/sbin:$PATH"
    while true; do
      if ioreg -p IOUSB -l -w 0 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "Imprint"; then
        sleep 5
        qmk-keyboard-setup 0x01 || true
        sleep 30
      fi
      sleep 5
    done
  '';
in
{
  # Monitor USB devices and run qmk-keyboard-setup when Cyboard Imprint is connected
  # Note: macOS doesn't have direct udev equivalent, so we poll for the device
  launchd.user.agents.qmk-keyboard-monitor = {
    serviceConfig = {
      ProgramArguments = [ "${monitorScript}" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/qmk-keyboard-monitor.log";
      StandardErrorPath = "/tmp/qmk-keyboard-monitor.err";
      Label = "org.nixos.qmk-keyboard-monitor";
    };
  };
}
