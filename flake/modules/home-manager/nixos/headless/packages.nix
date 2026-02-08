{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    btdu
  ];
}
