{
  # See the snapshots ls /snapshots/
  # See the space taken sudo btrfs filesystem du -s /snapshots/*
  # Manually delete a snapshot: sudo btrfs subvolume delete /snapshots/persistent.2025...

  services.btrbk.instances = {
    persistent = {
      onCalendar = "hourly";
      settings = {
        snapshot_dir = "/snapshots";
        snapshot_preserve = "7d 5w";
        snapshot_preserve_min = "2d";
        subvolume = "/persistent";
      };
    };
  };
}
