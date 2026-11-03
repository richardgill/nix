{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  activationDependencies =
    if pkgs.stdenv.isDarwin then [ "setupLaunchAgents" ] else [ "reloadSystemd" ];
  decryptSecrets =
    if pkgs.stdenv.isDarwin then
      ''
        domain="gui/$(id -u)"
        run /bin/launchctl bootout --wait "$domain/org.nix-community.home.sops-nix" || true
        run ${lib.escapeShellArg config.launchd.agents.sops-nix.config.Program}
        run /bin/launchctl bootstrap "$domain" "${config.home.homeDirectory}/Library/LaunchAgents/org.nix-community.home.sops-nix.plist"
      ''
    else
      ''
        run ${config.systemd.user.systemctlPath} --user restart sops-nix.service
      '';
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    defaultSopsFile = ../../../../secrets/secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    secrets = lib.genAttrs [
      "kagi-api-key"
      "kagi-session-token"
      "kagi-search-token"
      "exa-api-key"
    ] (_: { });
  };

  custom.secretFiles = {
    kagiApiKey = config.sops.secrets."kagi-api-key".path;
    kagiSessionToken = config.sops.secrets."kagi-session-token".path;
    kagiSearchToken = config.sops.secrets."kagi-search-token".path;
    exaApiKey = config.sops.secrets."exa-api-key".path;
  };

  # Wait for decryption before Firefox activation, not just for launchctl bootstrap.
  # Keep the upstream user services for login; stop the Darwin job before synchronous decryption.
  # https://github.com/Mic92/sops-nix/blob/master/modules/home-manager/sops.nix
  home.activation.sops-nix = lib.mkForce (
    lib.hm.dag.entryBetween [ "copyFirefoxConfig" ] activationDependencies decryptSecrets
  );
}
