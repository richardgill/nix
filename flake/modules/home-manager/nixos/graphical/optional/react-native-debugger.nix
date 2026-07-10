{ lib, pkgs, ... }:
let
  reactNativeDebugger = pkgs.symlinkJoin {
    name = "react-native-debugger-nixos";
    paths = [ pkgs.react-native-debugger ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/react-native-debugger
      makeWrapper ${lib.getExe pkgs.react-native-debugger} $out/bin/react-native-debugger \
        --add-flags "--disable-gpu" \
        --add-flags "--disable-software-rasterizer"
    '';
  };
in
{
  home.packages = [ reactNativeDebugger ];
}
