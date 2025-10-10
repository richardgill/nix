{
  vars,
  ...
}:
{
  imports = [
    ../shared/stylix.nix
  ];

  stylix = {
    # Darwin-specific font size overrides
    fonts.sizes = {
      applications = 12;
      terminal = 13;
      desktop = 11;
      popups = 11;
    };
  };

  system.activationScripts.postActivation.text = ''
    echo "Setting dark mode..."
    /usr/bin/osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' || true

    echo "Setting desktop wallpaper..."
    /usr/bin/osascript -e 'tell application "System Events" to tell every desktop to set picture to POSIX file "/System/Library/Desktop Pictures/Ventura Graphic.madesktop"' 2>/dev/null || true
  '';
}
