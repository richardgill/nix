{ hostName, ... }:
{
  networking = {
    inherit hostName;
    computerName = hostName;
    localHostName = hostName;
  };
}
