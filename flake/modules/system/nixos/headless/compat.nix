{
  lib,
  config,
  ...
}:
{
  # Pragmatic compatibility layer for non-Nix binaries
  # https://fzakaria.com/2025/02/26/nix-pragmatism-nix-ld-and-envfs

  # nix-ld enables running prebuilt binaries by providing dynamic library loading
  programs.nix-ld.enable = true;

  # envfs creates FUSE filesystem at /bin and /usr/bin to fix scripts expecting #!/bin/bash etc
  services.envfs.enable = true;

  # Workaround for envfs with boot.loader.systemd-boot.enable (used for secure boot)
  # Based on https://github.com/linyinfeng/dotfiles/blob/master/nixos/profiles/services/envfs/default.nix
  # systemd requires /usr being properly populated before switching root
  # envfs disables the population of /usr/bin/env, so we pre-create the directory
  # fileSystems."/usr/bin".options = lib.mkIf config.boot.initrd.systemd.enable [
  #   "x-systemd.requires=modprobe@fuse.service"
  #   "x-systemd.after=modprobe@fuse.service"
  # ];

  boot.initrd.systemd.tmpfiles.settings = lib.mkIf config.boot.initrd.systemd.enable {
    "50-usr-bin" = {
      "/sysroot/usr/bin" = {
        d = {
          group = "root";
          mode = "0755";
          user = "root";
        };
      };
    };
  };

  # Disable /bin mount to avoid duplicate mount errors
  # systemd-fstab-generator canonicalizes /bin to /usr/bin
  # fileSystems."/bin".enable = lib.mkIf config.boot.initrd.systemd.enable false;
}
