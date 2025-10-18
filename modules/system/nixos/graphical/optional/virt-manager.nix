{ pkgs, vars, ... }:
{
  # needed for graphics in VMs, which hyprland guests need.
  hardware.graphics.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";

    qemu = {
      package = pkgs.qemu_kvm;
      ovmf = {
        enable = true;
        packages = [
          (pkgs.OVMFFull.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd
        ];
      };
      swtpm.enable = true;
      runAsRoot = false;
      vhostUserPackages = with pkgs; [ virtiofsd ];
      verbatimConfig = ''
        user = "${vars.userName}"
        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm",
          "/dev/rtc", "/dev/hpet",
          "/dev/dri/renderD128"
        ]
      '';
    };
  };

  programs.virt-manager.enable = true;

  users.users.${vars.userName}.extraGroups = [ "libvirtd" ];

  environment.systemPackages = with pkgs; [
    spice
    spice-gtk
    virt-viewer
    win-virtio
    win-spice
  ];
}
