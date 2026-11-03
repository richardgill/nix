# Extracts template configuration from a NixOS configuration
# Used by: flake.nix templateConfig output, templates.nix derivation
# Accepts the user's Home Manager config directly, including in standalone Home Manager.
{
  lib,
  pkgs,
  config,
}:
let
  homeDir = config.home.homeDirectory;

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

  firefoxProfilePath = if pkgs.stdenv.isDarwin then "Profiles/default" else "default";

  defaultAiAgent = "pi";
in
{
  beeperEnabled = config.custom.agentSkills.beeper.enable;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  isAarch64Linux = pkgs.stdenv.isLinux && pkgs.stdenv.hostPlatform.isAarch64;
  inherit homeDir;
  homeDirectory = homeDir;
  zshPath = "${pkgs.zsh}/bin/zsh";
  coreUtilsPath = "${pkgs.coreutils}";
  kagiApiKeyPath = config.custom.secretFiles.kagiApiKey;
  kagiSessionTokenPath = config.custom.secretFiles.kagiSessionToken;
  exaApiKeyPath = config.custom.secretFiles.exaApiKey;
  defaultShell = "${pkgs.zsh}/bin/zsh";
  gwsSkillsPath = "${pkgs.unstablePkgs.gws.src}/skills";
  catppuccinPlugin = "${pkgs.tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux";
  resurrectPlugin = "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux";
  continuumPlugin = "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux";
  inherit
    firefoxProfilePath
    firefoxProxyPacPathUrlEncoded
    defaultAiAgent
    ;
  profilePath = firefoxProfilePath;
}
