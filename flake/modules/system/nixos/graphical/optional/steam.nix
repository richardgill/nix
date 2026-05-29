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
    # Alternative: If running Steam normally instead of gamescopeSession,
    # use per-game launch options in Steam.
    # Rocket League on Radeon 780M, 1080p target:
    #     mangohud gamemoderun gamescope -w 1920 -h 1080 -W 1920 -H 1080 -f -- %command% -dx11
    # Rocket League fallback if 1080p is not stable, 900p upscaled to 1080p:
    #     mangohud gamemoderun gamescope -w 1600 -h 900 -W 1920 -H 1080 -F fsr -f -- %command% -dx11
    # Rocket League in-game settings: Fullscreen, VSync off, AA off or FXAA low,
    # Render Quality/Detail, World Detail, Particle Detail = Performance,
    # Effect Intensity low, Ambient Occlusion/Dynamic Shadows/Bloom/DoF/Motion Blur/Weather/Light Shafts/Lens Flare off.
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
