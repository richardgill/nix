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

  firefoxProxyPacPathUrlEncoded =
    if pkgs.stdenv.isDarwin then
      "${homeDir}/Library/Application%20Support/Firefox/proxy.pac"
    else
      "${firefoxConfigDir}/default/proxy.pac";

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
  defaultAiAgent = "pi";
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
  kagiSessionTokenPath = config.sops.secrets."kagi-session-token".path;
  openaiApiKeyPath = config.sops.secrets."openai-api-key".path;
  exaApiKeyPath = config.sops.secrets."exa-api-key".path;
  defaultShell = "${pkgs.zsh}/bin/zsh";
  catppuccinPlugin = "${pkgs.tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux";
  resurrectPlugin = "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux";
  continuumPlugin = "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux";
  inherit
    firefoxProfilePath
    firefoxProxyPacPathUrlEncoded
    defaultEngineIdHash
    defaultAiAgent
    ;
  profilePath = firefoxProfilePath;
}
