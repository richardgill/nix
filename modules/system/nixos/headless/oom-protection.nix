{ lib, ... }:
{
  systemd.oomd.enable = lib.mkForce false;

  # More aggressively kill processes when getting close to no memory
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
    enableNotifications = true;
    extraArgs = [
      "--avoid"
      "'^(Hyprland|waybar|systemd|systemd-.*|dbus-.*|pipewire|wireplumber|Xwayland|firefox|kitty)$'"
      "--prefer"
      "'^(Web Content|Isolated Web Co|electron|chromium|slack|discord|teams)$'"
    ];
  };

  # Kernel tuning for zram optimization
  # https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
  # https://github.com/NixOS/nixpkgs/pull/268121
  boot.kernel.sysctl = {
    "vm.overcommit_memory" = 1;
    "vm.swappiness" = 180;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };

  zramSwap = {
    enable = lib.mkForce true;
    algorithm = "zstd";
    memoryPercent = 150;
  };
}
