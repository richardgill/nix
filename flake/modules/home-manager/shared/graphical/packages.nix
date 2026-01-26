{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    cmus
    qmk
    gcc-arm-embedded # Needed to build cyboard keyboard firmware
  ];
}
