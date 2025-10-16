_:
{
  # Pragmatic compatibility layer for non-Nix binaries
  # https://fzakaria.com/2025/02/26/nix-pragmatism-nix-ld-and-envfs

  # nix-ld enables running prebuilt binaries by providing dynamic library loading
  programs.nix-ld.enable = true;

  # envfs creates FUSE filesystem at /bin and /usr/bin to fix scripts expecting #!/bin/bash etc
  services.envfs.enable = true;
}
