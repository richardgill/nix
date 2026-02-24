{ pkgs, vars, ... }:
{
  environment.systemPackages = with pkgs; [
    android-studio
  ];

  programs.adb.enable = true;

  users.users.${vars.userName}.extraGroups = [ "adbusers" "kvm" ];
}
