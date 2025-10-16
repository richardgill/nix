{ vars, ... }:
{
  # Configuration is stored in .config/syncthing which is persisted via impermanence
  services.syncthing = {
    enable = true;
    user = vars.userName;
    group = "users";
    dataDir = "/home/${vars.userName}/.local/share/syncthing";
    configDir = "/home/${vars.userName}/.config/syncthing";
    overrideDevices = false;
    overrideFolders = false;
    settings = {
      options = {
        localAnnounceEnabled = true;
      };
    };
  };
}
