{
  lib,
  pkgs,
  config,
  osConfig,
  vars,
  ...
}:
let
  homeManager = import ../../../../utils/home-manager.nix { inherit lib config; };
  homeDir = config.home.homeDirectory;
  inherit (homeManager) sourceDirectory;

  # Import shared templates
  templates = import ./templates.nix { inherit lib pkgs config osConfig vars; };
  inherit (templates) builtTemplates;

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
          && !(lib.hasSuffix ".hbs" name)
          && (pkgs.stdenv.isLinux || !(builtins.elem name linuxOnlyScripts))
        ) scriptFiles
      );

in
{
  # Cmus files (from built templates)
  home.activation.copyCmusFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${homeDir}/.config/cmus
    cp -f ${builtTemplates}/cmus/start ${homeDir}/.config/cmus/start
    chmod +x ${homeDir}/.config/cmus/start
    cp -f ${builtTemplates}/cmus/rc ${homeDir}/.config/cmus/rc
    cp -f ${builtTemplates}/cmus/tokyo-night.theme ${homeDir}/.config/cmus/tokyo-night.theme
  '';

  home.file =
    scriptsEntries
    // {
      ".config/nvim".source =
        config.lib.file.mkOutOfStoreSymlink "${homeDir}/code/nix-private/modules/home-manager/dot-files/nvim";
    }
    // sourceDirectory {
      target = "Scripts/lib";
      source = ../../dot-files/Scripts/lib;
    }
    // {
      # From built templates (in Nix store)
      # Note: .zshenv is managed by programs.zsh.envExtra in zsh.nix
      ".zprofile".source = "${builtTemplates}/zprofile/zprofile";
      ".config/alacritty/alacritty.toml".source = "${builtTemplates}/alacritty/alacritty.toml";
      ".config/alacritty/themes".source = "${builtTemplates}/alacritty/themes";
      ".config/ghostty/config".source = "${builtTemplates}/ghostty/config";
      ".config/ripgrep/.ripgreprc".source = "${builtTemplates}/ripgrep/ripgreprc";
      ".config/ripgrep/.rgignore".source = "${builtTemplates}/ripgrep/rgignore";
      # Note: .config/mise/config.toml is managed by mise.nix
      # Note: .zshrc is managed by programs.zsh in zsh.nix

      # Claude config (from built templates)
      ".claude/CLAUDE.md".source = "${builtTemplates}/ai-agents/claude/CLAUDE.md";
      ".claude/settings.json".source =
        config.lib.file.mkOutOfStoreSymlink "${homeDir}/code/nix-private/modules/home-manager/dot-files/ai-agents/claude/settings.json";
      ".claude/commands".source = "${builtTemplates}/ai-agents/commands";
      ".claude/skills".source = "${builtTemplates}/ai-agents/claude/skills";
      ".claude/agents".source = "${builtTemplates}/ai-agents/claude/agents";
      ".claude/rules".source = "${builtTemplates}/ai-agents/claude/rules";
      ".claude/statusline.sh" = {
        source = "${builtTemplates}/ai-agents/claude/statusline.sh";
        executable = true;
      };

      # OpenCode uses same CLAUDE.md template
      ".config/opencode/AGENTS.md".source = "${builtTemplates}/ai-agents/claude/CLAUDE.md";
      ".config/opencode/opencode.json".source = "${builtTemplates}/ai-agents/opencode/opencode.json";
      ".config/opencode/agent".source = "${builtTemplates}/ai-agents/opencode/agent";
      ".config/opencode/prompts".source = "${builtTemplates}/ai-agents/opencode/prompts";
      # OpenCode uses singular "command" directory (shared with claude/amp)
      ".config/opencode/command".source = "${builtTemplates}/ai-agents/commands";

      # Codex config
      ".codex".source = "${builtTemplates}/ai-agents/codex";

      # Ampcode config (~/.config/amp/)
      ".config/amp/AGENTS.md".source = "${builtTemplates}/ai-agents/ampcode/AGENTS.md";
      ".config/amp/settings.json".source = "${builtTemplates}/ai-agents/ampcode/settings.json";
      ".config/amp/commands".source = "${builtTemplates}/ai-agents/commands";

      # Static files (not templated)
      ".config/obs-studio".source =
        config.lib.file.mkOutOfStoreSymlink "${homeDir}/code/nix-private/modules/home-manager/dot-files/obs-studio";
      ".config/git/config".source = ../../dot-files/git/config;
      ".config/git/ignore".source = ../../dot-files/git/ignore;
      ".config/delta/themes.gitconfig".source = ../../dot-files/git/delta-themes.gitconfig;
      ".config/git/templates/hooks/post-checkout".source = ../../dot-files/git/hooks/post-checkout;
      ".lesskey".source = ../../dot-files/lesskey;
      ".stignore".source = ../../dot-files/stignore;
      "code/.rgignore".source = ../../dot-files/code/rgignore;
      ".config/btop/btop.conf".source = ../../dot-files/btop/btop.conf;
      ".config/oh-my-posh".source = ../../dot-files/oh-my-posh;
      ".config/sesh".source = ../../dot-files/sesh;
      ".ssh/config".source = ../../dot-files/ssh/config;
      ".config/yazi".source = ../../dot-files/yazi;
    };
}
