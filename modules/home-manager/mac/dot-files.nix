_:
{
  home.file = {
    ".config/karabiner".source = ./dot-files/karabiner;
    ".hammerspoon".source = ./dot-files/hammerspoon;
  };

  home.activation.copyKeyboardLayout = {
    after = [ "writeBoundary" ];
    before = [ ];
    data = ''
      mkdir -p "$HOME/Library/Keyboard Layouts"
      cp -f "${./dot-files}/Keyboard Layouts/unicode-hex-input-fixed-british.keylayout" "$HOME/Library/Keyboard Layouts/unicode-hex-input-fixed-british.keylayout"
    '';
  };

  # Mutable configs: copied instead of symlinked so apps can write to them
  # home.file creates read-only symlinks to /nix/store which breaks apps that need to modify their config

  home.activation.copyVSCodeConfig = {
    after = [ "writeBoundary" ];
    before = [ ];
    data = ''
      chmod -R +w "$HOME/Library/Application Support/Code/User" 2>/dev/null || true
      rm -rf "$HOME/Library/Application Support/Code/User"
      mkdir -p "$HOME/Library/Application Support/Code"
      cp -rf "${./dot-files}/Application Support/Code/"* "$HOME/Library/Application Support/Code/"
    '';
  };

  home.activation.copyCursorConfig = {
    after = [ "writeBoundary" ];
    before = [ ];
    data = ''
      chmod -R +w "$HOME/Library/Application Support/Cursor/User" 2>/dev/null || true
      rm -rf "$HOME/Library/Application Support/Cursor/User"
      mkdir -p "$HOME/Library/Application Support/Cursor"
      cp -rf "${./dot-files}/Application Support/Cursor/"* "$HOME/Library/Application Support/Cursor/"
    '';
  };

  home.activation.copySolConfig = {
    after = [ "writeBoundary" ];
    before = [ ];
    data = ''
      mkdir -p "$HOME/Library/Application Support/com.ospfranco.sol"
      cp -rf "${./dot-files}/Application Support/com.ospfranco.sol/"* "$HOME/Library/Application Support/com.ospfranco.sol/"
      mkdir -p "$HOME/Library/Preferences"
      cp -f "${./dot-files}/Preferences/com.ospfranco.sol.plist" "$HOME/Library/Preferences/com.ospfranco.sol.plist"
    '';
  };

  home.activation.copyAppPreferences = {
    after = [ "writeBoundary" ];
    before = [ ];
    data = ''
      mkdir -p "$HOME/Library/Preferences"
      cp -f "${./dot-files}/Preferences/com.knollsoft.Rectangle.plist" "$HOME/Library/Preferences/com.knollsoft.Rectangle.plist"
      cp -f "${./dot-files}/Preferences/eu.exelban.Stats.plist" "$HOME/Library/Preferences/eu.exelban.Stats.plist"
      cp -f "${./dot-files}/Preferences/com.getcoldturkey.blocker.plist" "$HOME/Library/Preferences/com.getcoldturkey.blocker.plist"
    '';
  };

  home.activation.copyFlameshotConfig = {
    after = [ "writeBoundary" ];
    before = [ ];
    data = ''
      mkdir -p "$HOME/.config/flameshot"
      cp -f "${./dot-files}/.config/flameshot/flameshot.ini" "$HOME/.config/flameshot/flameshot.ini"
    '';
  };
}
