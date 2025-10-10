{
  # See the snapshots ls /btrbk/
  # See the space taken sudo btrfs filesystem du -s /btrbk/*
  # Manually delete a snapshot: sudo btrfs subvolume delete /btrbk/persistent.2025...

  services.btrbk.instances = {
    persistent = {
      onCalendar = "hourly";
      settings = {
        snapshot_dir = "/btrbk";
        snapshot_preserve = "7d 5w";
        snapshot_preserve_min = "2d";
        subvolume = "/persistent";
      };
    };
  };
}
