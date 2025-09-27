{
  lib,
  pkgs,
  config,
  ...
}: {
  programs.firefox = {
    enable = true;
    profiles.default = {
      isDefault = true;
      search = {
        force = true;
        default = "Kagi";
        engines = {
          "Kagi" = {
            urls = [{
              template = "https://kagi.com/search";
              params = [
                { name = "q"; value = "{searchTerms}"; }
              ];
            }];
            icon = "https://kagi.com/assets/favicon.ico";
            definedAliases = [ "@kagi" ];
          };
        };
      };
      settings = {
        "browser.startup.homepage" = "about:blank";
        "browser.newtabpage.enabled" = false;
        "browser.search.region" = "GB";
        "browser.search.isUS" = true;
        "general.useragent.locale" = "en-US";

        # Privacy settings
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.donottrackheader.enabled" = true;
        "privacy.clearOnShutdown.cookies" = false;
        "privacy.clearOnShutdown.history" = false;

        # Security settings
        "security.tls.version.min" = 3;
        "dom.security.https_only_mode" = true;

        # UI preferences
        "browser.toolbars.bookmarks.visibility" = "never";
        "browser.tabs.warnOnClose" = false;
        "browser.download.useDownloadDir" = true;
        "browser.download.dir" = "${config.home.homeDirectory}/Downloads";

        # Performance
        "browser.cache.disk.enable" = false;
        "browser.sessionstore.privacy_level" = 2;

        # Disable telemetry
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;

        # Extension settings for impermanence
        "extensions.autoDisableScopes" = 0;

        # New sidebar layout
        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;
        "sidebar.position_start" = false;
        "sidebar.visibility.sidebar-main" = true;
      };
    };

    # Extension policies
    policies = {
      ExtensionSettings = {
        "*" = {
          installation_mode = "blocked";
        };
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };
      };
    };
  };
}
