{ pkgs, ... }:
{
  # Custom desktop entry with -h flag to extract archives into a folder named after the archive, preventing tar-bombing
  xdg.desktopEntries = {
    file-roller-extract-here = {
      name = "File Roller (Extract to Folder)";
      comment = "Extract archives into a folder named after the archive";
      exec = "${pkgs.file-roller}/bin/file-roller -h %U";
      icon = "org.gnome.FileRoller";
      type = "Application";
      categories = [ "Utility" "Archiving" "GTK" ];
      mimeType = [
        "application/zip"
        "application/x-tar"
        "application/x-compressed-tar"
        "application/x-bzip-compressed-tar"
        "application/x-xz-compressed-tar"
        "application/x-7z-compressed"
        "application/x-rar"
        "application/gzip"
        "application/x-gzip"
        "application/bzip2"
        "application/x-bzip"
      ];
    };
  };
}
