{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  sbctlPath = "/var/lib/sbctl";
  INITIAL_INSTALL = builtins.getEnv "INITIAL_INSTALL" == "1";
  _ = builtins.trace "INITIAL_INSTALL environment variable: '${builtins.getEnv "INITIAL_INSTALL"}' -> ${builtins.toString INITIAL_INSTALL}" null;
in
{
  # Lanzaboote Secure Boot Configuration with TPM2 Auto-Unlock
  # https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md
  # https://laniakita.com/blog/nixos-fde-tpm-hm-guide#part-25-unlocking-luks-with-tpm2-using-systemd-cryptenroll
  #
  # Setup steps:
  # 1. clone-and-install.sh will run sbctl create-keys for you. So you should already have keys, but if not rerun: sudo sbctl create-keys
  # 2. Import this module in your machine configuration
  # 3. Rebuild: just switch
  # 4. Check most .efi are ✅ using: sudo sbctl verify
  # 5. Reboot and put Secure Boot into Setup Mode in UEFI/BIOS settings (advisable to set bios password for security)
  # 6. Boot back into NixOS and enroll keys: sudo sbctl enroll-keys --microsoft
  # 7. Verify status: sudo sbctl status
  # 8. Reboot and enable Secure Boot in BIOS
  # 9. Verify boot worked: bootctl status
  # 10. Automatically unlock LUKS using TPM2:
  #        https://github.com/Misterio77/nix-config/blob/main/hosts/common/optional/secure-boot.nix
  #        Find device: lsblk -f | grep -i luks (usually /dev/nvme0n1p2)
  #        Run: sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7+12+13+14+15:sha256=0000000000000000000000000000000000000000000000000000000000000000 --wipe-slot=tpm2 /dev/<your-device>
  #        After enrollment, reboot - LUKS should unlock automatically via TPM2!

  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  boot.loader.systemd-boot.enable = lib.mkForce INITIAL_INSTALL;

  # enable secure boot
  boot.lanzaboote = {
    enable = !INITIAL_INSTALL;
    pkiBundle = sbctlPath;
  };

  environment.systemPackages = [
    pkgs.sbctl
    pkgs.tpm2-tools
    pkgs.tpm2-tss
  ];

  # Might help according to Arch wiki but depends on which TPM we have (e.g., Microsoft Pluton)
  boot.initrd.availableKernelModules = [ "tpm_crb" ];

  boot.initrd.systemd.enable = !INITIAL_INSTALL;
}
