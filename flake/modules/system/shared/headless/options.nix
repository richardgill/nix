{
  lib,
  vars,
  pkgs,
  ...
}:
{
  options = {
    customDirs = {
      music = lib.mkOption {
        type = lib.types.str;
        default =
          if pkgs.stdenv.isDarwin then "/Users/${vars.userName}/Music" else "/home/${vars.userName}/Music";
      };
    };
  };
}
