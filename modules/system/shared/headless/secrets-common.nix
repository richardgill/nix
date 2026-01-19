{
  vars,
  pkgs,
  ...
}:
let
  # Define all the API key secrets that should be available on both Darwin and NixOS
  apiKeySecrets = [
    "anthropic-api-key"
    "kagi-api-key"
    "kagi-search-token"
    "tavily-api-key"
    "openai-api-key"
    "joist-api-key"
    "beeper-api-token"
    "exa-api-key"
  ];

  # Generate secret configurations with appropriate ownership
  mkSecretConfig = name: {
    inherit name;
    value = {
      owner = vars.userName;
      # Only set group on Linux
    }
    // (if pkgs.stdenv.isLinux then { group = "users"; } else { });
  };
in
{
  # Common sops configuration
  sops = {
    defaultSopsFile = ../../../../secrets/secrets.yaml;

    # Set appropriate age key path based on platform
    age =
      if pkgs.stdenv.isDarwin then
        {
          keyFile = "/Users/${vars.userName}/.config/sops/age/keys.txt";
        }
      else
        {
          sshKeyPaths = [ "/nix/secret/initrd/ssh_host_ed25519_key" ];
        };

    # Generate secrets config from the list
    secrets = builtins.listToAttrs (map mkSecretConfig apiKeySecrets);
  };
}
