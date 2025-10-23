{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    mangohud
  ];

  programs.steam = {
    enable = true;
    # Steam needs linux file system to look like normal linux, so nix runs it in a 'container', and only packages which are listed here are available in the container
    extraPackages = with pkgs; [
      gamemode
      mangohud
    ];
    # login to steam from gdm (cog in bottow right)
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

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  programs.gamemode.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
