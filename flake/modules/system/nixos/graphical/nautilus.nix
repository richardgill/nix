{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.nautilus
    pkgs.ffmpegthumbnailer
  ];

  services.gnome.sushi.enable = true;
}
