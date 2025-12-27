function FindProxyForURL(url, host) {
  var vpnDomains = [
    "ifconfig.me",
    "icanhazip.com",
  ];

  for (var i = 0; i < vpnDomains.length; i++) {
    if (dnsDomainIs(host, "." + vpnDomains[i]) || host === vpnDomains[i]) {
      // return "PROXY your-proxy-server:1234";
    }
  }

  return "DIRECT";
}
