{
  lib,
  pkgs,
  config,
  osConfig,
  ...
}:
let
  template = import ../../../../utils/template.nix { inherit pkgs; };
  homeManager = import ../../../../utils/home-manager.nix { inherit lib config; };
  homeDir = config.home.homeDirectory;
  inherit (template) renderMustache;
  inherit (homeManager) sourceDirectory;

  # Programmatically generate Scripts entries
  scriptFiles = builtins.readDir ../../dot-files/Scripts;
  linuxOnlyScripts = [
    "paste"
    "screen-record"
    "launch-app"
    "launch-terminal-app"
    "launch-ghostty"
  ];
  scriptsEntries =
    lib.mapAttrs'
      (
        name: type:
        lib.nameValuePair "Scripts/${name}" {
          source = ../../dot-files/Scripts + "/${name}";
        }
      )
      (
        lib.filterAttrs (
          name: type:
          type == "regular"
          && !(lib.hasSuffix ".mustache" name)
          && (pkgs.stdenv.isLinux || !(builtins.elem name linuxOnlyScripts))
        ) scriptFiles
      );

  cmusStartFile = pkgs.writeText "cmus-start" (
    builtins.readFile (
      renderMustache "cmus-start" ../../dot-files/cmus/start.mustache {
        musicDir = osConfig.customDirs.music;
      }
    )
  );

  cmusRcFile = pkgs.writeText "cmus-rc" (
    builtins.readFile (
      renderMustache "cmus-rc" ../../dot-files/cmus/rc.mustache {
        musicDir = osConfig.customDirs.music;
      }
    )
  );

in
{
  home.activation.copyCmusFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.home.homeDirectory}/.config/cmus
    cp -f ${cmusStartFile} ${config.home.homeDirectory}/.config/cmus/start
    chmod +x ${config.home.homeDirectory}/.config/cmus/start
    cp -f ${cmusRcFile} ${config.home.homeDirectory}/.config/cmus/rc
    cp -f ${../../dot-files/cmus/tokyo-night.theme} ${config.home.homeDirectory}/.config/cmus/tokyo-night.theme
  '';

  home.file =
    scriptsEntries
    // (sourceDirectory {
      target = ".config/nvim";
      source = ../../dot-files/nvim;
      outOfStoreSymlinks = [ "lazy-lock.json" ];
    })
    // {
      "Scripts/beep" = {
        text = builtins.readFile (
          renderMustache "beep-script" ../../dot-files/Scripts/beep.mustache {
            inherit (pkgs.stdenv) isDarwin;
            inherit (pkgs.stdenv) isLinux;
          }
        );
        executable = true;
      };
      ".zshenv" = {
        text = builtins.readFile (
          renderMustache "zshenv" ../../dot-files/zshenv.mustache {
            anthropicApiKeyPath = osConfig.sops.secrets."anthropic-api-key".path;
            kagiApiKeyPath = osConfig.sops.secrets."kagi-api-key".path;
            tavilyApiKeyPath = osConfig.sops.secrets."tavily-api-key".path;
            openaiApiKeyPath = osConfig.sops.secrets."openai-api-key".path;
            joistApiKeyPath = osConfig.sops.secrets."joist-api-key".path;
          }
        );
      };
      ".claude/CLAUDE.md".source = ../../dot-files/claude/CLAUDE.md;
      ".claude/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/code/nix-private/modules/home-manager/dot-files/claude/settings.json";
      ".claude/agents".source = ../../dot-files/claude/agents;
      ".claude/commands".source = ../../dot-files/claude/commands;
      ".codex".source = ../../dot-files/codex;
      ".config/git/config".source = ../../dot-files/git/config;
      ".config/git/ignore".source = ../../dot-files/git/ignore;
      ".config/delta/themes.gitconfig".source = ../../dot-files/git/delta-themes.gitconfig;
      ".config/git/templates/hooks/post-checkout".source = ../../dot-files/git/hooks/post-checkout;
      ".lesskey".source = ../../dot-files/lesskey;
      ".stignore".source = ../../dot-files/stignore;
      "code/.rgignore".source = ../../dot-files/code/rgignore;
      ".zprofile".text = builtins.readFile (
        renderMustache "zprofile" ../../dot-files/zprofile.mustache {
          inherit (pkgs.stdenv) isDarwin;
        }
      );
      ".config/alacritty/alacritty.toml".text = builtins.readFile (
        renderMustache "alacritty-config" ../../dot-files/alacritty/alacritty.toml.mustache {
          zshPath = "${pkgs.zsh}/bin/zsh";
        }
      );
      ".config/alacritty/themes".source = ../../dot-files/alacritty/themes;
      ".config/ghostty/config".text = builtins.readFile (
        renderMustache "ghostty-config" ../../dot-files/ghostty/config.mustache {
          inherit (pkgs.stdenv) isDarwin;
          inherit (pkgs.stdenv) isLinux;
          zshPath = "${pkgs.zsh}/bin/zsh";
        }
      );
      ".config/opencode/AGENTS.md".text = builtins.readFile (
        renderMustache "opencode-agents" ../../dot-files/opencode/AGENTS.md.mustache {
          inherit homeDir;
        }
      );
      ".config/oh-my-posh".source = ../../dot-files/oh-my-posh;
      ".config/ripgrep/.ripgreprc".text = builtins.readFile (
        renderMustache "ripgreprc" ../../dot-files/ripgrep/ripgreprc.mustache {
          inherit homeDir;
        }
      );
      ".config/ripgrep/.rgignore".source = ../../dot-files/ripgrep/rgignore;
      ".config/sesh".source = ../../dot-files/sesh;
      ".config/yazi".source = ../../dot-files/yazi;
      ".zshrc" = {
        text = builtins.readFile (
          renderMustache "zshrc" ../../dot-files/zsh/zshrc.mustache {
            inherit (pkgs.stdenv) isDarwin isLinux;
            coreUtilsPath = "${pkgs.coreutils}";
          }
        );
      };
    };
}
