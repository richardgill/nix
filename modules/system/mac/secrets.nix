{
  inputs,
  ...
}:
{
  imports = [
    inputs.sops-nix.darwinModules.sops
    ../shared/secrets-common.nix
  ];

  # Any Darwin-specific secrets configuration can go here
  # The common API keys are already configured in secrets-common.nix
}
