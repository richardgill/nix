{
  pkgs,
  vars,
  ...
}:
let
  androidHome = "/home/${vars.userName}/Android/Sdk";
in
{
  environment.systemPackages = with pkgs; [
    android-tools
    jdk17
  ];

  environment.sessionVariables = {
    JAVA_HOME = pkgs.jdk17.home;
    ANDROID_HOME = androidHome;
    ANDROID_SDK_ROOT = androidHome;
  };

  environment.extraInit = ''
    export PATH="${androidHome}/platform-tools:${androidHome}/emulator:$PATH"
  '';
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libbsd
    libcxx
    libdrm
    libgbm
    libpng
    libpulseaudio
    libxkbcommon
    mesa
    nspr
    nss
    pango
    systemd
    util-linux
    libice
    libsm
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxcb
    libxkbfile
    zlib
  ];

  users.users.${vars.userName}.extraGroups = [
    "adbusers"
    "kvm"
  ];

  environment.persistence."/persistent".users.${vars.userName}.directories = [
    "Android/Sdk"
    ".android"
    ".config/.android"
    ".java"
  ];
}
