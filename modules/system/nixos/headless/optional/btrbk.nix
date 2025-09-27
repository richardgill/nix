{
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