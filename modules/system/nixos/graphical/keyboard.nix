{
  config,
  lib,
  pkgs,
  inputs,
  qmkKeyboardSetupScript,
  vars,
  ...
}:
{
  # Logs: journalctl --user -u xremap --no-pager
  # Restart: systemctl --user restart xremap
  imports = [
    inputs.xremap-flake.nixosModules.default
    ../../shared/qmk-keyboard-setup.nix
  ];

  services.xremap = {
    # Needed to detect currently active application
    withWlroots = true;
    # This didn't work and needed to use wlroots
    # withHypr = true;
    enable = true;
    userName = vars.userName;
    serviceMode = "user";
    debug = false;
    config = {
      virtual_modifiers = [ "CapsLock" ];
      keymap = [
        {
          name = "Hyper key mappings";
          exact_match = true;
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
          name = "Universal bindings exact match";
          exact_match = true;
          remap = {
            "KEY_102ND" = "F12";
          };
        }
        {
          name = "Universal bindings";
          exact_match = false; # We want home + shift to work still
          remap = {
            "Super-Left" = "Home";
            "Super-Right" = "End";
          };
        }
        {
          name = "Mac-like bindings";
          exact_match = true;
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
            "Super-x" = "C-x";
            "Super-z" = "C-z";
            "Super-Shift-z" = "C-Shift-z";
          };
        }
        {
          name = "Mac-like bindings for Firefox";
          exact_match = true;
          application = {
            only = [
              "firefox"
              "Firefox"
            ];
          };
          remap = {
            "Super-s" = "C-s";
            "Super-f" = "C-f";
            "Super-w" = "C-w";
            "Super-t" = "C-t";
            "Super-r" = "C-r";
            "Super-Shift-r" = "C-Shift-r";
            "Super-Shift-p" = "C-Shift-p";
            "Super-l" = "C-l";
            "Super-Alt-i" = "C-Shift-i";
            "Super-BTN_LEFT" = "C-BTN_LEFT";
            "Super-equal" = "C-equal";
            "Super-minus" = "C-minus";
          };
        }
        {
          name = "Terminal bindings";
          exact_match = true;
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

  services.udev.extraRules = ''
    # QMK keyboard setup: Set Unicode mode to Linux when keyboard is connected
    SUBSYSTEM=="usb", ATTR{idVendor}=="4359", ATTR{idProduct}=="0000", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="qmk-keyboard-setup.service", MODE="0666"

    # Auto-restart xremap when keyboards are connected/disconnected
    # This prevents xremap crashes when keyboards are unplugged while xremap is running
    # SUBSYSTEM=="input" - only input devices (keyboards, mice, etc)
    # KERNEL=="event*" - only event interface devices (/dev/input/eventX)
    # ATTRS{name}=="*[Kk]eyboard*" - device name contains "keyboard" or "Keyboard"
    # ACTION=="add|remove" - when device is plugged in or unplugged
    # TAG+="systemd" - mark for systemd processing
    # ENV{SYSTEMD_USER_WANTS} - trigger this user service when event occurs
    SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="*[Kk]eyboard*", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="xremap-restart.service"
    SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="*[Kk]eyboard*", ACTION=="remove", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}="xremap-restart.service"
  '';

  systemd.user.services.qmk-keyboard-setup = {
    description = "Configure QMK keyboard Unicode mode on connection";
    path = config.environment.systemPackages;
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      ExecStart = "${qmkKeyboardSetupScript}/bin/qmk-keyboard-setup 0x02";
    };
  };

  systemd.user.services.xremap-restart = {
    description = "Restart xremap after keyboard plug/unplug events";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user restart xremap.service";
    };
  };
}
