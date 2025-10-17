{
  vars,
  ...
}:
{
  # https://nixos.wiki/wiki/Remote_disk_unlocking#Setup
  # Note: You need to make sure boot.initrd.kernelModules = [ "<your network device>" ]; is configured in your hardware-configuration.nix
  # Find the name using sudo lspci -v | grep -iA8 'network\\|ethernet'

  # Enables ssh access in initrd very early in book process so luks can be unlocked
  # You must ssh as root@<machine>:2222 to unlock luks
  boot.initrd.network = {
    enable = true;
    # Disabled due to bug where $ifaces variable gets populated with leading spaces
    # causing "can't find device ' enp2s0'" errors. See manual fix in postMountCommands below.
    # https://github.com/NixOS/nixpkgs/issues/285190
    flushBeforeStage2 = false;
    udhcpc = {
      enable = true;
    };
    ssh = {
      enable = true;
      port = 2222;
      shell = "/bin/cryptsetup-askpass";
      authorizedKeys = vars.sshAllPublicKeys;
      hostKeys = [ "/nix/secret/initrd/ssh_host_ed25519_key" ];
    };
  };

  # Manual flush before stage 2 to work around bug in flushBeforeStage2
  # This mirrors the original code from nixpkgs but fixes the $ifaces variable population
  # Original: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/initrd-network.nix
  # Bug: https://github.com/NixOS/nixpkgs/issues/285190
  #
  # To verify the flush is working after boot, check for errors in early boot logs:
  #   journalctl -b 0 --no-pager | head -300
  #   nmcli connection show
  boot.initrd.postMountCommands = ''
    ifaces=$(ip -o link show | awk -F': ' '$3 ~ /UP/ && $2 !~ /^lo$/ {print $2}')
    for iface in $ifaces; do
      ip address flush dev "$iface"
      ip link set dev "$iface" down
    done
  '';
}
