# Playwright browsers from pinned flake for agent-browser, testing, etc.
# https://github.com/pietdevries94/playwright-web-flake
{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  upstreamPlaywrightBrowsers =
    inputs.playwright.packages.${pkgs.stdenv.hostPlatform.system}.playwright-driver.browsers;
  # Layouts: https://github.com/pietdevries94/playwright-web-flake/blob/581efb42e8e259b504a8940583cb74bb3fc99d85/playwright-driver/default.nix
  # macOS: https://github.com/microsoft/playwright/blob/v1.58.0/packages/playwright-core/src/server/registry/index.ts
  chromiumExecutable =
    if pkgs.stdenv.isDarwin then
      "chrome-mac-${
        if pkgs.stdenv.hostPlatform.isAarch64 then "arm64" else "x64"
      }/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing"
    else
      "chrome-linux/chrome";
  playwrightBrowsers = pkgs.runCommand "playwright-browsers-compatible" { } ''
    mkdir -p "$out"
    cp -rs "${upstreamPlaywrightBrowsers}/." "$out/"
    find "$out" -type d -exec chmod u+w {} +

    set -- "${upstreamPlaywrightBrowsers}"/chromium-[0-9]*/"${chromiumExecutable}"
    if [ "$#" -ne 1 ] || [ ! -x "$1" ]; then
      echo "Expected exactly one executable Chromium browser, found: $*" >&2
      exit 1
    fi
    mkdir -p "$out/bin"
    ln -s "$1" "$out/bin/chromium"

    ${lib.optionalString pkgs.stdenv.isLinux ''
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
    ''}
  '';
in
{
  home.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${playwrightBrowsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    PUPPETEER_EXECUTABLE_PATH = "${playwrightBrowsers}/bin/chromium";
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD = "true";
  };

  home.activation.linkPlaywrightBrowsers = lib.mkIf pkgs.stdenv.isDarwin (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "$HOME/Library/Caches/ms-playwright"
      for browser in "${playwrightBrowsers}"/*-[0-9]*/; do
        name=$(basename "$browser")
        ln -sfn "$browser" "$HOME/Library/Caches/ms-playwright/$name"
      done
    ''
  );
}
