{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    cmus
  ];
}
