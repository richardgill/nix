{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    defaultSopsFile = ../../../../secrets/secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    secrets = lib.genAttrs [
      "kagi-api-key"
      "kagi-session-token"
      "exa-api-key"
    ] (_: { });
  };

  # During boot the user manager is reachable but reports "starting", which
  # upstream treats as absent. Reload units restored by Home Manager before
  # queuing secrets; waiting for default.target here would block activation.
  # Upstream activation workaround: https://github.com/Mic92/sops-nix/pull/491
  # Missing secrets reports: https://github.com/Mic92/sops-nix/issues/478
  # Related boot timing reports: https://github.com/nix-community/home-manager/issues/3172
  home.activation.sops-nix = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
    lib.mkForce (
      lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
        if ${config.systemd.user.systemctlPath} --user show-environment >/dev/null 2>&1; then
          run ${config.systemd.user.systemctlPath} --user daemon-reload
          run ${config.systemd.user.systemctlPath} --user --no-block restart sops-nix.service
        fi
      ''
    )
  );

  custom.secretFiles = {
    kagiApiKey = config.sops.secrets."kagi-api-key".path;
    kagiSessionToken = config.sops.secrets."kagi-session-token".path;
    exaApiKey = config.sops.secrets."exa-api-key".path;
  };

}
