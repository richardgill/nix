{
  pkgs,
  ...
}:
{
  imports = [ ../../shared/graphical/fonts.nix ];

  # list fonts: fc-list : family | sort -u
  fonts = {
    packages = with pkgs; [
      # Core fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf

      # UI fonts
      inter

      # Additional fonts
      dejavu_fonts
      freefont_ttf
    ];

    fontconfig = {
      enable = true;

      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [
          "Inter"
          "Noto Sans"
        ];
        monospace = [
          "Hack Nerd Font"
          "JetBrains Mono Nerd Font"
        ];
      };

      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <!-- Map ui-monospace (CSS keyword used by GitHub) to Hack Nerd Font since fontconfig doesn't recognize it by default -->
          <match target="pattern">
            <test qual="any" name="family"><string>ui-monospace</string></test>
            <edit name="family" mode="prepend" binding="same"><string>Hack Nerd Font</string></edit>
          </match>
        </fontconfig>
      '';

      # Enable embedded bitmaps for better emoji support
      useEmbeddedBitmaps = true;
    };

    # Enable font directory for Flatpak support
    fontDir.enable = true;
  };
}
