{
  config,
  pkgs,
  lib,
  ...
}:

{
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

      # Nerd Fonts (NixOS 25.05+ syntax)
      nerd-fonts.hack
      nerd-fonts.jetbrains-mono

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

      # Enable embedded bitmaps for better emoji support
      useEmbeddedBitmaps = true;
    };

    # Enable font directory for Flatpak support
    fontDir.enable = true;
  };
}
