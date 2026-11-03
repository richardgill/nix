{
  config,
  inputs,
  lib,
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

  custom.secretFiles = {
    kagiApiKey = config.sops.secrets."kagi-api-key".path;
    kagiSessionToken = config.sops.secrets."kagi-session-token".path;
    exaApiKey = config.sops.secrets."exa-api-key".path;
  };

}
