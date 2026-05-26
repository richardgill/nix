# Test by creating memory heavy processes with: nix-shell -p stress-ng --run "stress-ng --vm 1 --vm-bytes 5G --timeout 60s"
{ lib, ... }:
{
  systemd.oomd = {
    enable = true;
    enableUserSlices = true; # Let systemd-oomd kill runaway user app/session scopes under memory pressure
    settings.OOM = {
      DefaultMemoryPressureLimit = "50%";
      DefaultMemoryPressureDurationSec = "15s";
      SwapUsedLimit = "70%";
    };
  };

  systemd.slices."user".sliceConfig.ManagedOOMSwap = "kill";

  # More aggressively kill processes when getting close to no memory
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 25; # Start killing before the system reaches a hard OOM cliff
    freeMemKillThreshold = 15; # Escalate from SIGTERM to SIGKILL if available memory drops below this percent
    freeSwapThreshold = 20; # React once swap is also getting tight
    freeSwapKillThreshold = 5; # Escalate from SIGTERM to SIGKILL if free swap drops below this percent
    enableNotifications = true;
    reportInterval = 60;
    extraArgs = [
      # Safe because GUI apps launch in isolated UWSM app scopes/process groups instead of Niri's process group.
      "-g"
      "--avoid"
      "^(niri|waybar|systemd|systemd-.*|dbus-.*|pipewire|wireplumber|Xwayland|xwayland-satellite|kitty)$"
    ];
  };

  # Kernel tuning for zram optimization, zram is a way of storing swap in ram itself with compression. Trades off CPU (compression) for memory.
  # https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
  # https://github.com/NixOS/nixpkgs/pull/268121
  boot.kernel.sysctl = {
    "vm.overcommit_memory" = 1;
    "vm.swappiness" = 100;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };

  zramSwap = {
    enable = lib.mkForce true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
}
