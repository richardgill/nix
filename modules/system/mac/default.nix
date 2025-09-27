{
  pkgs,
  vars,
  ...
}: {
  imports = [
    ../shared
    ./dock.nix
    ./packages.nix
    ./secrets.nix
    ./stylix.nix
  ];

  nix = {
    package = pkgs.nix;
    settings = {
      trusted-users = [
        "root"
        "@admin"
      ];
    };
  };

  # inspo: https://github.com/nix-darwin/nix-darwin/issues/1339
  ids.gids.nixbld = 350;

  security.pam.services.sudo_local.touchIdAuth = true;

  services = {
    tailscale.enable = true;
  };

  users.users.${vars.userName}.home = "/Users/${vars.userName}";

  system = {
    primaryUser = vars.userName;
    startup.chime = false;
    defaults = {
      loginwindow.LoginwindowText = "If lost, contact ${vars.userEmail}";
      screencapture.location = "~/Screenshots";

      dock = {
        autohide = false;
        mru-spaces = false;
        tilesize = 48;
        wvous-br-corner = 4;
        wvous-bl-corner = 11;
        wvous-tr-corner = 5;
      };

      finder = {
        AppleShowAllExtensions = true;
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
        # inspo: https://apple.stackexchange.com/questions/261163/default-value-for-nsglobaldomain-initialkeyrepeat
        KeyRepeat = 2;
        InitialKeyRepeat = 15;
        "com.apple.swipescrolldirection" = false;
      };

      CustomUserPreferences = {
        "com.apple.spotlight" = {
          orderedItems = [
            { enabled = 1; name = "APPLICATIONS"; }
            { enabled = 1; name = "SYSTEM_PREFS"; }
            { enabled = 0; name = "DIRECTORIES"; }
            { enabled = 0; name = "PDF"; }
            { enabled = 0; name = "FONTS"; }
            { enabled = 0; name = "DOCUMENTS"; }
            { enabled = 0; name = "MESSAGES"; }
            { enabled = 0; name = "CONTACT"; }
            { enabled = 0; name = "EVENT_TODO"; }
            { enabled = 0; name = "IMAGES"; }
            { enabled = 0; name = "BOOKMARKS"; }
            { enabled = 0; name = "MUSIC"; }
            { enabled = 0; name = "MOVIES"; }
            { enabled = 0; name = "PRESENTATIONS"; }
            { enabled = 0; name = "SPREADSHEETS"; }
            { enabled = 0; name = "SOURCE"; }
            { enabled = 0; name = "MENU_DEFINITION"; }
            { enabled = 0; name = "MENU_OTHER"; }
            { enabled = 0; name = "MENU_CONVERSION"; }
            { enabled = 0; name = "MENU_EXPRESSION"; }
            { enabled = 0; name = "MENU_WEBSEARCH"; }
            { enabled = 0; name = "MENU_SPOTLIGHT_SUGGESTIONS"; }
          ];
        };
      };
    };
  };

  local = {
    dock = {
      enable = true;
      username = vars.userName;
      entries = [
      ];
    };
  };

  system.stateVersion = 4;
}
