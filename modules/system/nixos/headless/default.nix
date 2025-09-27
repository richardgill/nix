{
  inputs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ../../shared
    ./secrets.nix
    ./avahi.nix
    ./system.nix
    ./impermanence.nix
    ./networking.nix
    ./packages.nix
    ./mise.nix
    ./remote-unlock.nix
    ./ssh.nix
  ];
}
