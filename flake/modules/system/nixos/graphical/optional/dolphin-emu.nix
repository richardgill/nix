{
  pkgs,
  vars,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    dolphin-emu
  ];

  services.udev.packages = with pkgs; [
    dolphin-emu
  ];

  hardware.graphics.enable = true;

  environment.persistence."/persistent".users.${vars.userName}.directories = [
    ".cache/dolphin-emu"
    ".config/dolphin-emu"
    ".local/share/dolphin-emu"
  ];
}
