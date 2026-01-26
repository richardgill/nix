# Fixes login crash in nixpkgs bambu-studio: https://github.com/NixOS/nixpkgs/issues/440951
# Based on working AppImage solution: https://github.com/NixOS/nixpkgs/issues/440951#issuecomment-2556266529
self: super:
let
  pname = "bambu-studio";
  version = "02.03.00.70";
  ubuntu_version = "24.04_PR-8184";
  name = "BambuStudio";

  src = super.fetchurl {
    url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/Bambu_Studio_ubuntu-${ubuntu_version}.AppImage";
    sha256 = "sha256:60ef861e204e7d6da518619bd7b7c5ab2ae2a1bd9a5fb79d10b7c4495f73b172";
  };

  appimageContents = super.appimageTools.extract { inherit pname version src; };
in
{
  bambu-studio = super.appimageTools.wrapType2 {
    inherit name pname version src;

    profile = ''
      export SSL_CERT_FILE="${super.cacert}/etc/ssl/certs/ca-bundle.crt"
      export GIO_MODULE_DIR="${super.glib-networking}/lib/gio/modules/"
      export LOCALE_ARCHIVE="${super.glibcLocales}/lib/locale/locale-archive"
    '';

    extraPkgs =
      pkgs: with pkgs; [
        cacert
        glib
        glib-networking
        glibcLocales
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        webkitgtk_4_1
      ];

    extraInstallCommands = ''
      # Install desktop file from extracted AppImage
      install -Dm644 ${appimageContents}/BambuStudio.desktop $out/share/applications/bambu-studio.desktop
      substituteInPlace $out/share/applications/bambu-studio.desktop \
        --replace 'Exec=AppRun' "Exec=$out/bin/${pname}"

      # Install icon from extracted AppImage
      install -Dm644 ${appimageContents}/BambuStudio.png $out/share/pixmaps/bambu-studio.png
    '';
  };
}
