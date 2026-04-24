{ lib, ... }:
{
  boot.kernel.sysctl = {
    "kernel.sysrq" = lib.mkDefault 1;
  };

  systemd.coredump.extraConfig = ''
    Storage=external
    Compress=yes
    ProcessSizeMax=8G
    ExternalSizeMax=8G
  '';

  systemd.tmpfiles.rules = [
    "d /var/log/crash 0755 root root - -"
    "d /var/log/crash/pstore 0755 root root - -"
  ];

  systemd.services.capture-pstore = {
    description = "Capture pstore logs";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    unitConfig.ConditionPathExists = "/sys/fs/pstore";
    serviceConfig.Type = "oneshot";
    script = ''
      shopt -s nullglob
      files=(/sys/fs/pstore/*)

      if [ "''${#files[@]}" -eq 0 ]; then
        exit 0
      fi

      boot_id="$(cat /proc/sys/kernel/random/boot_id)"
      target="/var/log/crash/pstore/$boot_id"

      mkdir -p "$target"
      cp -a /sys/fs/pstore/. "$target/"
    '';
  };
}
