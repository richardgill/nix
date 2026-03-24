# Playwright browsers from pinned flake for agent-browser, testing, etc.
# https://github.com/pietdevries94/playwright-web-flake
{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  playwrightBrowsers = inputs.playwright.packages.${pkgs.stdenv.hostPlatform.system}.playwright-driver.browsers;
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
