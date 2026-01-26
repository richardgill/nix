{ inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ../../shared/headless
    ./1password.nix
    ./avahi.nix
    ./compat.nix
    ./docker.nix
    ./eternal-terminal-server.nix
    ./impermanence.nix
    ./networking.nix
    ./oom-protection.nix
    ./packages.nix
    ./power-management.nix
    ./secrets.nix
    ./ssh.nix
    ./systemd.nix
    ./system.nix
  ];

  home-manager.backupFileExtension = "backup";
}
