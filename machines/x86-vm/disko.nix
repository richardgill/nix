# WARNING: Cannot update partitions with disko in-place, so get this right first time!
# https://github.com/nix-community/disko/issues/295
{ hostName, ... }:
{
  boot = {
    supportedFilesystems = [ "btrfs" ];
    # Needed to resume from hibernate
    kernelParams = [
      # https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Acquire_swap_file_offset
      # Get the offset with: sudo btrfs inspect-internal map-swapfile -r /.swapvol/swapfile
      "resume_offset=533760"
    ];
    resumeDevice = "/dev/disk/by-partlabel/disk-main-luks";
  };

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";
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
                name = "root_vg_${hostName}";
                askPassword = true; # Prompt for password during installation
                settings = {
                  bypassWorkqueues = true; # Only recommended for NVME SSDs
                  allowDiscards = true; # Important for SSD lifespan if no hardcore security requirement
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
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
                      swap.swapfile.size = "12G";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
