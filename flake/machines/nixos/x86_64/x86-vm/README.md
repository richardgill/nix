Setting up a VM in virtual-manager that works with btrfs you must set the 'firmware' to uefi in virtual-manager: https://community.clearlinux.org/t/efi-in-virt-manager/1788/3

Hyprland only works with graphics with hardware acceleration:

- Change Video Model from "QXL" to "Virtio" in virt-manager. Check: enable hardware acceleration. 
- Change Display Spice -> Check: Open Gl and set listen: None

