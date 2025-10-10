{ hostName, ... }:
{
  networking = {
    hostName = hostName;
    computerName = hostName;
    localHostName = hostName;
  };
}