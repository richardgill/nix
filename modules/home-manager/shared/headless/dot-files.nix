{
  lib,
  pkgs,
  vars,
  config,
  osConfig,
  ...
}:
let
  utils = import ../../../../utils { inherit pkgs; };
  homeDir = config.home.homeDirectory;

  # Programmatically generate Scripts entries
  scriptFiles = builtins.readDir ../../dot-files/Scripts;
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
          && (pkgs.stdenv.isLinux || (name != "paste" && name != "screenRecord"))
        ) scriptFiles
      );
in
{
  home.file = scriptsEntries // {
    "Scripts/beep" = {
      text = builtins.readFile (
        utils.renderMustache "beep-script" ../../dot-files/Scripts/beep.mustache {
          inherit (pkgs.stdenv) isDarwin;
          inherit (pkgs.stdenv) isLinux;
        }
      );
      executable = true;
    };
    ".zshenv" = {
      text = builtins.readFile (
        utils.renderMustache "zshenv" ../../dot-files/zshenv.mustache {
          anthropicApiKeyPath = osConfig.sops.secrets."anthropic-api-key".path;
          kagiApiKeyPath = osConfig.sops.secrets."kagi-api-key".path;
          tavilyApiKeyPath = osConfig.sops.secrets."tavily-api-key".path;
          openaiApiKeyPath = osConfig.sops.secrets."openai-api-key".path;
          joistApiKeyPath = osConfig.sops.secrets."joist-api-key".path;
        }
      );
    };
    ".claude/CLAUDE.md".source = ../../dot-files/claude/CLAUDE.md;
    ".claude/settings.json".source = ../../dot-files/claude/settings.json;
    ".claude/agents".source = ../../dot-files/claude/agents;
    ".claude/commands".source = ../../dot-files/claude/commands;
    ".codex".source = ../../dot-files/codex;
    ".gitconfig".source = ../../dot-files/git/gitconfig;
    ".config/delta/themes.gitconfig".source = ../../dot-files/git/delta-themes.gitconfig;
    ".lesskey".source = ../../dot-files/lesskey;
    ".stignore".source = ../../dot-files/stignore;
    "code/.rgignore".source = ../../dot-files/code/rgignore;
    ".zprofile".text = builtins.readFile (
      utils.renderMustache "zprofile" ../../dot-files/zprofile.mustache {
        inherit (pkgs.stdenv) isDarwin;
      }
    );
    ".config/alacritty/alacritty.toml".text = builtins.readFile (
      utils.renderMustache "alacritty-config" ../../dot-files/alacritty/alacritty.toml.mustache {
        zshPath = "${pkgs.zsh}/bin/zsh";
      }
    );
    ".config/alacritty/themes".source = ../../dot-files/alacritty/themes;
    ".config/ghostty/config".text = builtins.readFile (
      utils.renderMustache "ghostty-config" ../../dot-files/ghostty/config.mustache {
        inherit (pkgs.stdenv) isDarwin;
        inherit (pkgs.stdenv) isLinux;
        zshPath = "${pkgs.zsh}/bin/zsh";
      }
    );
    ".config/opencode/AGENTS.md".text = builtins.readFile (
      utils.renderMustache "opencode-agents" ../../dot-files/opencode/AGENTS.md.mustache {
        inherit homeDir;
      }
    );
    ".config/nvim".source = ../../dot-files/nvim;
    ".config/oh-my-posh".source = ../../dot-files/oh-my-posh;
    ".config/ripgrep/config".text = builtins.readFile (
      utils.renderMustache "ripgreprc" ../../dot-files/ripgrep/ripgreprc.mustache {
        inherit homeDir;
      }
    );
    ".config/ripgrep/.rgignore".source = ../../dot-files/ripgrep/rgignore;
    ".config/sesh".source = ../../dot-files/sesh;
    ".config/yazi".source = ../../dot-files/yazi;
    ".zshrc" = {
      text = builtins.readFile (
        utils.renderMustache "zshrc" ../../dot-files/zsh/zshrc.mustache {
          inherit (pkgs.stdenv) isDarwin;
          coreUtilsPath = "${pkgs.coreutils}";
        }
      );
    };
  };
}
