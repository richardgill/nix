{ pkgs, ... }:
{
  imports = [
    ../headless/android.nix
  ];

  environment.systemPackages = with pkgs; [
    android-studio
  ];
}
