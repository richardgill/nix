{ lib, pkgs, ... }:
{
  boot.kernelParams = [ "log_buf_len=32M" ];

  boot.kernelModules = [ "efi_pstore" ];

  boot.kernel.sysctl = {
    "kernel.sysrq" = lib.mkDefault 1;
  };

  services.journald = {
    storage = "persistent";
    rateLimitBurst = 20000;
    extraConfig = ''
      Compress=yes
      SyncIntervalSec=30s
      SystemMaxUse=4G
      SystemKeepFree=2G
      MaxRetentionSec=1month
      MaxFileSec=1day
    '';
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

  systemd.services.crash-heartbeat = {
    description = "Record crash diagnostics heartbeat";
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail

      log=/var/log/crash/heartbeat.log
      mkdir -p /var/log/crash

      if [ -f "$log" ] && [ "$(${pkgs.coreutils}/bin/stat -c %s "$log")" -gt 10485760 ]; then
        ${pkgs.coreutils}/bin/mv "$log" "$log.$(${pkgs.coreutils}/bin/date +%Y%m%d%H%M%S)"
      fi

      {
        echo "=== $(${pkgs.coreutils}/bin/date --iso-8601=seconds) ==="
        echo "boot_id=$(cat /proc/sys/kernel/random/boot_id)"
        echo "uptime=$(cat /proc/uptime)"
        echo "loadavg=$(cat /proc/loadavg)"
        ${pkgs.gnugrep}/bin/grep -E '^(MemAvailable|SwapFree|Dirty|Writeback):' /proc/meminfo || true
        echo "btrfs_device_stats:"
        ${pkgs.btrfs-progs}/bin/btrfs device stats / 2>&1 || true
        echo "nvme_smart:"
        for dev in /dev/nvme*n1; do
          [ -e "$dev" ] || continue
          echo "$dev"
          ${pkgs.nvme-cli}/bin/nvme smart-log "$dev" -H 2>&1 | ${pkgs.gnugrep}/bin/grep -E 'critical_warning|temperature|available_spare|percentage_used|unsafe_shutdowns|media_errors|num_err_log_entries' || true
        done
        echo "recent_kernel_storage:"
        ${pkgs.systemd}/bin/journalctl -k --since '-2 minutes' --no-pager -o short-iso 2>/dev/null \
          | ${pkgs.gnugrep}/bin/grep -Ei 'btrfs|cryptroot|dm-0|nvme|I/O error|blk_update|checksum|corrupt|read-only|timeout|reset|abort' || true
        echo
      } >> "$log"
    '';
  };

  systemd.timers.crash-heartbeat = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
      AccuracySec = "10s";
      Persistent = true;
    };
  };

  systemd.services.crash-marker = {
    description = "Record clean boot and shutdown markers";
    wantedBy = [ "multi-user.target" ];
    conflicts = [ "shutdown.target" ];
    before = [ "shutdown.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p /var/log/crash; echo start $(${pkgs.coreutils}/bin/date --iso-8601=seconds) boot_id=$(cat /proc/sys/kernel/random/boot_id) >> /var/log/crash/markers.log'";
      ExecStop = "${pkgs.bash}/bin/bash -c 'echo clean-shutdown $(${pkgs.coreutils}/bin/date --iso-8601=seconds) boot_id=$(cat /proc/sys/kernel/random/boot_id) >> /var/log/crash/markers.log'";
    };
  };
}
