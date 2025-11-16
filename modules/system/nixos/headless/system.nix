{
  lib,
  pkgs,
  vars,
  ...
}:
{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 30;
    };
    efi.canTouchEfiVariables = true;
    timeout = 10;
  };

  users.users.${vars.userName} = {
    isNormalUser = true;
    description = lib.mkDefault vars.userName;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
  };

  services = {
    fstrim.enable = true;
  };

  security.sudo.wheelNeedsPassword = false;

  # Allow 10 sudo attempts
  security.sudo.extraConfig = ''
    Defaults passwd_tries=10
  '';

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = lib.mkDefault "23.11";
}
