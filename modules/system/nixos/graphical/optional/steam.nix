{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true; # Creates a full Steam session outside hyprland
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
