{ vars, ... }:
{
  # To view and diff Apple defaults settings:
  # 1. Save current defaults: defaults read > /tmp/defaults.txt
  # 2. Make changes to your system
  # 3. Diff against saved: diff /tmp/defaults.txt <(defaults read)
  #
  # defaults Documentation:
  # - https://macos-defaults.com/
  # - https://github.com/kevinSuttle/macOS-Defaults
  # - https://github.com/0xAndrii/mac-setup/blob/main/settings.sh

  system.stateVersion = 4;

  system = {
    primaryUser = vars.userName;
    startup.chime = false;
    defaults = {
      loginwindow.LoginwindowText = "If lost, contact ${vars.userEmail}";
      screencapture.location = "~/Screenshots";

      dock = {
        autohide = false;
        mru-spaces = false;
        show-recents = false;
        # Only show open apps in the drawer
        static-only = false;
        tilesize = 48;
        # Hot Corners: 1 = disabled, 2 = Mission Control, 3 = Show Application Windows, 4 = Desktop, 5 = Start Screen Saver, 6 = Disable Screen Saver, 10 = Put Display to Sleep, 11 = Launchpad, 12 = Notification Center
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        FXPreferredViewStyle = "clmv";
      };

      menuExtraClock = {
        ShowSeconds = false;
        Show24Hour = true;
        ShowAMPM = false;
      };

      NSGlobalDomain = {
        AppleICUForce24HourTime = true;
        AppleInterfaceStyle = "Dark";
        AppleInterfaceStyleSwitchesAutomatically = false;
        # inspo: https://apple.stackexchange.com/questions/261163/default-value-for-nsglobaldomain-initialkeyrepeat
        KeyRepeat = 2;
        InitialKeyRepeat = 15;
        "com.apple.swipescrolldirection" = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
      };

      # Hide widgets on desktop and in Stage Manager
      WindowManager = {
        EnableStandardClickToShowDesktop = false;
        StandardHideDesktopIcons = true;
        StandardHideWidgets = true;
        StageManagerHideWidgets = true;
      };

      CustomUserPreferences = {
        "com.apple.LaunchServices" = {
          LSQuarantine = false;
        };
        "com.apple.BluetoothAudioAgent" = {
          # Increase Bluetooth audio quality
          "Apple Bitpool Min (editable)" = 40;
        };
        # speed up mouse
        "com.apple.mouse" = {
          scaling = 2;
        };
        # Remote widgets
        "com.apple.chronod" = {
          effectiveRemoteWidgetsEnabled = false;
          remoteWidgetsEnabled = false;
        };
        # attempts to make the fixed british hex input the only (and default input)
        # this one works with emojis
        "com.apple.HIToolbox" = {
          AppleEnabledInputSources = [
            {
              InputSourceKind = "Keyboard Layout";
              "KeyboardLayout ID" = -12952;
              "KeyboardLayout Name" = "Unicode Hex Input - fixed british";
            }
          ];
          AppleInputSourceHistory = [
            {
              InputSourceKind = "Keyboard Layout";
              "KeyboardLayout ID" = -12952;
              "KeyboardLayout Name" = "Unicode Hex Input - fixed british";
            }
          ];
        };
        "com.apple.inputsources" = {
          AppleEnabledThirdPartyInputSources = [
            {
              InputSourceKind = "Keyboard Layout";
              "KeyboardLayout ID" = -12952;
              "KeyboardLayout Name" = "Unicode Hex Input - fixed british";
            }
          ];
        };

      };
    };
  };
}
