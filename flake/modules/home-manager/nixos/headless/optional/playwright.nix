# Playwright browsers from pinned flake for agent-browser, testing, etc.
# https://github.com/pietdevries94/playwright-web-flake
{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  upstreamPlaywrightBrowsers = inputs.playwright.packages.${pkgs.stdenv.hostPlatform.system}.playwright-driver.browsers;
  playwrightBrowsers = pkgs.runCommand "playwright-browsers-compatible" { } ''
    mkdir -p "$out"
    cp -rs "${upstreamPlaywrightBrowsers}/." "$out/"
    find "$out" -type d -exec chmod u+w {} +

    for browser in "${upstreamPlaywrightBrowsers}"/chromium-[0-9]*; do
      revision="''${browser##*-}"
      mkdir -p "$out/chromium-$revision/chrome-linux64"
      ln -s "$browser/chrome-linux/chrome" "$out/chromium-$revision/chrome-linux64/chrome"
    done

    for browser in "${upstreamPlaywrightBrowsers}"/chromium_headless_shell-*; do
      revision="''${browser##*-}"
      mkdir -p "$out/chromium_headless_shell-$revision/chrome-headless-shell-linux64"
      ln -s "$browser/chrome-linux/headless_shell" "$out/chromium_headless_shell-$revision/chrome-headless-shell-linux64/chrome-headless-shell"
    done
  '';
in
{
  home.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${playwrightBrowsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
  };

  home.activation.linkPlaywrightBrowsers = lib.mkIf pkgs.stdenv.isDarwin (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/Library/Caches/ms-playwright"
    for browser in "${playwrightBrowsers}"/*/; do
      name=$(basename "$browser")
      ln -sfn "$browser" "$HOME/Library/Caches/ms-playwright/$name"
    done
  '');
}
