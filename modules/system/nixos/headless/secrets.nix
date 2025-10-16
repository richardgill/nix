{ inputs, ... }:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ../../shared/headless/secrets-common.nix
  ];

  sops = {
    # inspo: https://github.com/Mic92/sops-nix/issues/427
    gnupg.sshKeyPaths = [ ];
  };
}
