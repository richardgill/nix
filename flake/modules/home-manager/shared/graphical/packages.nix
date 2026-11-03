{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    qmk
    sox
    gcc-arm-embedded # Needed to build cyboard keyboard firmware
  ];
}
