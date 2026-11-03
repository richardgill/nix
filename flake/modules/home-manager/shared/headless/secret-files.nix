{ lib, ... }:
{
  options.custom.secretFiles =
    lib.genAttrs
      [
        "kagiApiKey"
        "kagiSessionToken"
        "kagiSearchToken"
        "exaApiKey"
      ]
      (
        name:
        lib.mkOption {
          type = lib.types.strMatching "/.*";
          description = ''
            Absolute runtime credential-file path for ${name}. Use a string, not a
            Nix path literal: credential contents must never be copied into the Nix store.
          '';
        }
      );
}
