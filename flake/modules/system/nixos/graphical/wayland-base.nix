{
  ...
}:
{
  environment.sessionVariables = {
    # SSH_AUTH_SOCK = "/run/user/1000/ssh-agent";
    DISABLE_QT5_COMPAT = 0;
    GDK_BACKEND = "wayland";
    # xcb fallback was needed for android stuff
    QT_QPA_PLATFORM = "wayland;xcb";
    MOZ_ENABLE_WAYLAND = 1;
    NIXOS_OZONE_WL = 1;
    WLR_RENDERER = "vulkan";
    XDG_SESSION_TYPE = "wayland";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
  };

  services.xserver.enable = true;
  services.displayManager.gdm = {
    enable = true;
    autoSuspend = false;
  };

  services.gnome.gnome-keyring.enable = true;

  security.pam.services = {
    gdm.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
  };

  xdg.portal = {
    enable = true;
    # Disable portal for xdg-open: the portal's OpenURI implementation ignores mimeapps.list
    # and tries to launch Chrome with X11 settings instead of respecting Firefox as the default browser
    xdgOpenUsePortal = false;
  };
}
