{ inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ../../shared/headless
    ./1password.nix
    ./avahi.nix
    ./compat.nix
    ./impermanence.nix
    ./mise.nix
    ./networking.nix
    ./packages.nix
    ./power-management.nix
    ./remote-unlock.nix
    ./secrets.nix
    ./ssh.nix
    ./system.nix
  ];

  home-manager.backupFileExtension = "backup";
}
