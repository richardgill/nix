# Hack Nerd Font Mono assets

- Official Nerd Fonts release: v3.5.1
- Source: https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/Hack.tar.xz
- Source archive SHA-256: `cdd389472e10e2261520140ff1b382b4f8a226af5fd0b2735b975d31151d9c3c`
- Selected files: `HackNerdFontMono-Regular.ttf`, `HackNerdFontMono-Bold.ttf`, `HackNerdFontMono-Italic.ttf`, `HackNerdFontMono-BoldItalic.ttf`

Reproduce from a directory containing the downloaded archive:

```sh
mkdir extracted
for style in Regular Bold Italic BoldItalic; do
  tar -xJf Hack.tar.xz -C extracted "HackNerdFontMono-$style.ttf"
  fonttools ttLib.woff2 compress "extracted/HackNerdFontMono-$style.ttf" -o "HackNerdFontMono-$style.woff2"
done
tar -xJf Hack.tar.xz -C . LICENSE.md
```
