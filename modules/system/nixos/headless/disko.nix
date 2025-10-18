{
  device,
  resumeOffset,
  swapSize,
  isSsd,
}:
{
  inputs,
  config,
  ...
}:
{
  imports = [ inputs.disko.nixosModules.disko ];

  boot = {
    supportedFilesystems = [ "btrfs" ];
    kernelParams = [ "resume_offset=${resumeOffset}" ];
    resumeDevice = "/dev/disk/by-partlabel/disk-main-luks";
  };

  disko.devices.disk.main = {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            askPassword = true;
            settings = {
              bypassWorkqueues = isSsd;
              allowDiscards = true;
            };
            content = let
              this = config.disko.devices.disk.main.content.partitions.luks.content.content;
            in {
              type = "btrfs";
              extraArgs = [ "-f" ];
              postCreateHook = ''
                MNTPOINT=$(mktemp -d)
                mount -t btrfs "${this.device}" "$MNTPOINT"
                trap 'umount $MNTPOINT; rm -d $MNTPOINT' EXIT
                btrfs subvolume snapshot -r $MNTPOINT/root $MNTPOINT/root-blank
              '';
              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                    "subvol=root"
                  ];
                };
                "/persistent" = {
                  mountpoint = "/persistent";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                    "subvol=persistent"
                  ];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                    "subvol=nix"
                  ];
                };
                "/snapshots" = {
                  mountpoint = "/snapshots";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                    "subvol=snapshots"
                  ];
                };
                "/swap" = {
                  mountpoint = "/.swapvol";
                  mountOptions = [
                    "discard=async"
                    "noatime"
                    "nodatacow"
                    "nodatasum"
                  ];
                  swap.swapfile.size = swapSize;
                };
              };
            };
          };
        };
      };
    };
  };
}
