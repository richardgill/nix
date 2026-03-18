{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    cmus
    qmk
    sox
    gcc-arm-embedded # Needed to build cyboard keyboard firmware
  ];
}
