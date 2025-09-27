{
  lib,
  pkgs,
  config,
  ...
}: {
  home.file = {
    ".config/alfred".source = ./dot-files/alfred;
    ".config/karabiner".source = ./dot-files/karabiner;
    ".hammerspoon".source = ./dot-files/hammerspoon;
    "./Library/Application Support/Code".source = ./dot-files + "/Application Support/Code";
    "./Library/Application Support/Cursor".source = ./dot-files + "/Application Support/Cursor";
    "./Library/Application Support/monarch".source = ./dot-files + "/Application Support/monarch";
    "./Library/Keyboard Layouts/unicode-hex-input-fixed-british.keylayout".source = ./dot-files + "/Keyboard Layouts/unicode-hex-input-fixed-british.keylayout";
    "./Library/Preferences/com.getcoldturkey.blocker.plist".source = ./dot-files/Preferences/com.getcoldturkey.blocker.plist;
    "./Library/Preferences/com.knollsoft.Rectangle.plist".source = ./dot-files/Preferences/com.knollsoft.Rectangle.plist;
    "./Library/Preferences/com.lwouis.alt-tab-macos.plist".source = ./dot-files/Preferences/com.lwouis.alt-tab-macos.plist;
    "./Library/Preferences/com.raycast.macos.plist".source = ./dot-files/Preferences/com.raycast.macos.plist;
    "./Library/Preferences/eu.exelban.Stats.plist".source = ./dot-files/Preferences/eu.exelban.Stats.plist;
    "./Library/Preferences/pl.maketheweb.cleanshotx.plist".source = ./dot-files/Preferences/pl.maketheweb.cleanshotx.plist;
  };
}
