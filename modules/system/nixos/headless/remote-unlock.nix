{
  config,
  vars,
  ...
}:
{
  # https://nixos.wiki/wiki/Remote_disk_unlocking#Setup
  # Note: You need to make sure boot.initrd.kernelModules = [ "<your network device>" ]; is configured in your hardware-configuration.nix
  # Find the name using sudo lspci -v | grep -iA8 'network\\|ethernet'

  # Enables ssh access in initrd very early in book process so luks can be unlocked
  # You must ssh as root@<machine> to unlock
  boot.initrd.network = {
    enable = true;
    udhcpc = {
      enable = true;
    };
    ssh = {
      enable = true;
      shell = "/bin/cryptsetup-askpass";
      authorizedKeys = [ vars.sshPublicKeyPersonal ];
      hostKeys = [ "/nix/secret/initrd/ssh_host_ed25519_key" ];
    };
  };
}
