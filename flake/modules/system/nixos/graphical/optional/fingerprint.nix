_: {
  systemd.services.fprintd = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "simple";
  };

  services.fprintd.enable = true;

  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="05ba", ATTR{idProduct}=="000a", TEST=="power/control", ATTR{power/control}="on"
    ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="05ba", ATTR{idProduct}=="000a", TEST=="power/autosuspend_delay_ms", ATTR{power/autosuspend_delay_ms}="-1"
  '';
}
