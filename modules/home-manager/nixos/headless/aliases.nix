{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    (pkgs.writeShellScriptBin "open" ''
      exec ${pkgs.xdg-utils}/bin/xdg-open "$@" > /dev/null
    '')
  ];
}
