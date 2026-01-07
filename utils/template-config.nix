# Extracts template configuration from a NixOS configuration
# Used by: flake.nix templateConfig output, templates.nix derivation
{ lib, pkgs, config, userName }:
let
  hmConfig = config.home-manager.users.${userName};
  homeDir = hmConfig.home.homeDirectory;

  firefoxConfigDir =
    if pkgs.stdenv.isDarwin then
      "${homeDir}/Library/Application Support/Firefox"
    else
      "${homeDir}/.mozilla/firefox";

  firefoxProfilePathUrlEncoded =
    if pkgs.stdenv.isDarwin then
      "${homeDir}/Library/Application%20Support/Firefox/Profiles/default"
    else
      "${firefoxConfigDir}/default";

  firefoxProfilePath =
    if pkgs.stdenv.isDarwin then "Profiles/default" else "default";

  disclaimer =
    "By modifying this file, I agree that I am doing so "
    + "only within Firefox itself, using official, user-driven search "
    + "engine selection processes, and in a way which does not circumvent "
    + "user consent. I acknowledge that any attempt to change this file "
    + "from outside of Firefox is a malicious act, and will be responded "
    + "to accordingly.";

  salt = "default" + "Kagi" + disclaimer;

  defaultEngineIdHash = lib.removeSuffix "\n" (
    builtins.readFile (
      pkgs.runCommand "firefox-search-hash" { } ''
        echo -n "${salt}" | ${pkgs.openssl}/bin/openssl dgst -sha256 -binary | ${pkgs.coreutils}/bin/base64 > "$out"
      ''
    )
  );
in
{
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  inherit homeDir;
  homeDirectory = homeDir;
  zshPath = "${pkgs.zsh}/bin/zsh";
  coreUtilsPath = "${pkgs.coreutils}";
  musicDir = config.customDirs.music;
  anthropicApiKeyPath = config.sops.secrets."anthropic-api-key".path;
  kagiApiKeyPath = config.sops.secrets."kagi-api-key".path;
  tavilyApiKeyPath = config.sops.secrets."tavily-api-key".path;
  openaiApiKeyPath = config.sops.secrets."openai-api-key".path;
  joistApiKeyPath = config.sops.secrets."joist-api-key".path;
  beeperApiTokenPath = config.sops.secrets."beeper-api-token".path;
  defaultShell = "${pkgs.zsh}/bin/zsh";
  catppuccinPlugin = "${pkgs.tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux";
  resurrectPlugin = "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux";
  continuumPlugin = "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux";
  inherit firefoxProfilePath firefoxProfilePathUrlEncoded defaultEngineIdHash;
  profilePath = firefoxProfilePath;
}
