_:
{
  services.logind = {
    extraConfig = ''
      # Prevent automatic suspend on idle
      IdleAction=ignore
      IdleActionSec=infinity
    '';
  };
}
