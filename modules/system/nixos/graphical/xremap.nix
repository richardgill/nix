{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  # Logs: journalctl --user -u xremap --no-pager
  # Restart: systemctl --user restart xremap
  imports = [
    inputs.xremap-flake.nixosModules.default
  ];

  services.xremap = {
    # Needed to detect currently active application
    withWlroots = true;
    # This didn't work and needed to use wlroots
    # withHypr = true;
    enable = true; # Enable the systemd service
    userName = "rich";
    serviceMode = "user";
    debug = false;
    config = {
      virtual_modifiers = [ "CapsLock" ];
      keymap = [
        {
          name = "Hyper key mappings";
          remap = lib.listToAttrs (
            map (key: lib.nameValuePair "CapsLock-${key}" "SHIFT-C-M-SUPER-${key}") [
              "a"
              "b"
              "c"
              "d"
              "e"
              "f"
              "g"
              "h"
              "i"
              "j"
              "k"
              "l"
              "m"
              "n"
              "o"
              "p"
              "q"
              "r"
              "s"
              "t"
              "u"
              "v"
              "w"
              "x"
              "y"
              "z"
              "1"
              "2"
              "3"
              "4"
              "5"
              "6"
              "7"
              "8"
              "9"
            ]
          );
        }
        {
          name = "Universal bindings";
          remap = {
            "Super-Left" = "Home";
            "Super-Right" = "End";
            # tmux prefix for split keyboard
            "KEY_102ND" = "F12";
          };
        }
        {
          name = "Mac-like bindings";
          application = {
            not = [
              "Alacritty"
              "com.mitchellh.ghostty"
              "ghostty"
            ];
          };
          remap = {
            "Alt-Left" = "C-Left";
            "Alt-Right" = "C-Right";
            "Alt-Delete" = "C-Delete";
            "Alt-BackSpace" = "C-BackSpace";
            "Super-Delete" = [
              "Shift-End"
              "Delete"
            ];
            "Super-BackSpace" = [
              "Shift-Home"
              "Delete"
            ];
            "Super-a" = "C-a";
            "Super-c" = "C-c";
            "Super-v" = "C-v";
            "Super-alt-v" = "Super-alt-v";
          };
        }
        {
          name = "Mac-like bindings for Firefox";
          application = {
            only = [
              "firefox"
              "Firefox"
            ];
          };
          remap = {
            "Super-x" = "C-x";
            "Super-z" = "C-z";
            "Super-s" = "C-s";
            "Super-f" = "C-f";
            "Super-w" = "C-w";
            "Super-t" = "C-t";
            "Super-r" = "C-r";
            "Super-l" = "C-l";
          };
        }
        {
          name = "Terminal bindings";
          application = {
            only = [
              "Alacritty"
              "com.mitchellh.ghostty"
              "ghostty"
            ];
          };
          remap = {
            "Super-c" = "C-Shift-c";
            "Super-v" = "C-Shift-v";
          };
        }
      ];
    };
  };

  systemd.user.services.xremap = {
    serviceConfig = {
      Restart = "always";
      RestartSec = 3;
      StartLimitBurst = 5;
      StartLimitIntervalSec = 60;
    };
  };

  # Auto-restart xremap when keyboards are connected/disconnected
  # This prevents xremap crashes when keyboards are unplugged while xremap is running
  services.udev.extraRules = ''
    # Watch for keyboard device events in the input subsystem
    # SUBSYSTEM=="input" - only input devices (keyboards, mice, etc)
    # KERNEL=="event*" - only event interface devices (/dev/input/eventX)
    # ATTRS{name}=="*[Kk]eyboard*" - device name contains "keyboard" or "Keyboard"
    # ACTION=="add|remove" - when device is plugged in or unplugged
    # TAG+="systemd" - mark for systemd processing
    # ENV{SYSTEMD_USER_WANTS} - trigger this user service when event occurs
    SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="*[Kk]eyboard*", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="xremap-restart.service"
    SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="*[Kk]eyboard*", ACTION=="remove", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="xremap-restart.service"
  '';

  # Service that restarts xremap when triggered by udev events
  systemd.user.services.xremap-restart = {
    description = "Restart xremap after keyboard plug/unplug events";
    serviceConfig = {
      Type = "oneshot"; # Run once and exit (not a daemon)
      ExecStart = "${pkgs.systemd}/bin/systemctl --user restart xremap.service";
    };
  };

}
