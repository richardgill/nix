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
    # Alternative: If running Steam normally in Hyprland instead of gamescopeSession,
    # use these per-game launch options in Steam:
    #   gamescope -w 3840 -h 2160 -W 3840 -H 2160 --mangoapp -f -- %command% -dx11
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
        "--mangoapp"
      ];
    };
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    dedicatedServer.openFirewall = false;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
    extest.enable = true;
    protontricks.enable = true;
  };

  programs.gamescope = {
    enable = true;
    capSysNice = false;
  };

  programs.gamemode.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  # xbox wireless dongle adapter
  hardware.xone.enable = true;
}
