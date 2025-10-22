{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    mangohud
  ];

  programs.steam = {
    enable = true;
    # You can select "steam" in the gdm login screen to open steam in big picture mode
    gamescopeSession = {
      enable = true;
      args = [
        "-w"
        "3840"
        "-h"
        "2160"
        "-W"
        "3840"
        "-H"
        "2160"
      ];
      env = {
        MANGOHUD = "1";
      };
    };
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  programs.gamescope.enable = true;

  programs.gamemode.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
