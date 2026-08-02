{ config, inputs, ... }:
{
  imports = [ inputs.walker.homeManagerModules.default ];

  programs.walker = {
    enable = true;
    runAsService = true;

    config = {
      theme = "tokyo-night";
      close_when_open = true;
      force_keyboard_focus = true;
      selection_wrap = true;
      hide_quick_activation = true;
      providers = {
        default = [
          "desktopapplications"
          "calc"
        ];
        empty = [ "desktopapplications" ];
        max_results = 50;
        actions = {
          clipboard = [
            {
              action = "remove_all";
              unset = true;
            }
          ];
          desktopapplications = map (action: {
            inherit action;
            unset = true;
          }) [
            "pin"
            "unpin"
            "pinup"
            "pindown"
          ];
        };
      };
      placeholders = {
        default = {
          input = "Search applications";
          list = "No results";
        };
        clipboard = {
          input = "Search clipboard";
          list = "Clipboard is empty";
        };
      };
    };

    elephant = {
      providers = [
        "calc"
        "clipboard"
        "desktopapplications"
        "files"
        "providerlist"
        "runner"
        "symbols"
      ];
      settings = {
        auto_detect_launch_prefix = false;
        launch_prefix = "$HOME/Scripts/nixos/launch-in-app-scope";
        terminal_cmd = "ghostty -e";
      };
      provider = {
        clipboard.settings = {
          max_items = 200;
          pinned_on_top = true;
        };
        desktopapplications.settings = {
          history = false;
          show_actions = true;
        };
        files.settings = {
          search_dirs = [
            "${config.home.homeDirectory}/Documents"
            "${config.home.homeDirectory}/Downloads"
          ];
          fd_flags = [
            "--ignore-vcs"
            "--max-depth"
            "3"
            "--type"
            "file"
            "--type"
            "directory"
          ];
        };
      };
    };

    themes.tokyo-night = {
      style = builtins.readFile ./tokyo-night.css;
      layouts.item_desktopapplications = builtins.readFile ./item-desktopapplications.xml;
    };
  };
}
