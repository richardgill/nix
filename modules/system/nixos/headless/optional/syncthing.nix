_:
{
  # Configuration is stored in .config/syncthing which is persisted via impermanence
  services.syncthing = {
    enable = true;
    user = "rich";
    group = "users";
    dataDir = "/home/rich/.local/share/syncthing";
    configDir = "/home/rich/.config/syncthing";
    overrideDevices = false;
    overrideFolders = false;
    settings = {
      options = {
        localAnnounceEnabled = true;
      };
    };
  };
}
