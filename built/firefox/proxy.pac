function FindProxyForURL(url, host) {
  var allowedUrlPatterns = [
    /^https?:\/\/news\.ycombinator\.com\/item(\?|$).*/
  ];

  for (var i = 0; i < allowedUrlPatterns.length; i++) {
    if (allowedUrlPatterns[i].test(url)) {
      return "DIRECT";
    }
  }

  var blockedUrlPatterns = [
    /^https?:\/\/(www\.)?facebook\.com\/?$/,
    /^https?:\/\/(www\.)?facebook\.com\/home(\?|$).*/,
    /^https?:\/\/(www\.)?facebook\.com\/\?.*/,
    /^https?:\/\/(www\.)?facebook\.com\/watch(\/|$).*/,

    /^https?:\/\/(www\.)?instagram\.com\/?$/,
    /^https?:\/\/(www\.)?instagram\.com\/explore(\/|$).*/,
    /^https?:\/\/(www\.)?instagram\.com\/reels(\/|$).*/,

    /^https?:\/\/(www\.)?ft\.com\/?$/,
    /^https?:\/\/(www\.)?ft\.com\/\?.*/,

    /^https?:\/\/(www\.)?imgur\.com\/?$/,
    /^https?:\/\/(www\.)?imgur\.com\/gallery(\/|$).*/,
    /^https?:\/\/(www\.)?imgur\.com\/search(\/|$).*/,

    /^https?:\/\/news\.ycombinator\.com\/?$/,
    /^https?:\/\/news\.ycombinator\.com\/(news|newest|front|best|show|ask|jobs|newcomments|threads)(\?.*)?$/,

    /^https?:\/\/(www\.)?linkedin\.com\/feed(\/|$).*/,
    /^https?:\/\/(www\.)?linkedin\.com\/notifications(\/|$).*/,
    /^https?:\/\/(www\.)?linkedin\.com\/mynetwork(\/|$).*/,

    /^https?:\/\/(www\.)?reddit\.com\/?$/,
    /^https?:\/\/(www\.)?reddit\.com\/\?.*/,
    /^https?:\/\/(www\.)?reddit\.com\/r\/(all|popular)(\/|$).*/,
    /^https?:\/\/(www\.)?reddit\.com\/r\/[^/]+\/?$/,
    /^https?:\/\/(www\.)?reddit\.com\/r\/[^/]+\/(hot|new|top|rising|controversial)(\/|$).*/,
    /^https?:\/\/(www\.)?reddit\.com\/search(\/|$).*/,

    /^https?:\/\/(www\.)?theguardian\.com\/?$/,
    /^https?:\/\/(www\.)?theguardian\.com\/\?.*/,

    /^https?:\/\/(www\.)?x\.com\/?$/,
    /^https?:\/\/(www\.)?x\.com\/home(\?|$).*/,
    /^https?:\/\/(www\.)?x\.com\/explore(\?|$).*/,
    /^https?:\/\/(www\.)?x\.com\/notifications(\?|$).*/,
    /^https?:\/\/(www\.)?x\.com\/messages(\?|$).*/,

    /^https?:\/\/(www\.)?twitter\.com\/?$/,
    /^https?:\/\/(www\.)?twitter\.com\/home(\?|$).*/,
    /^https?:\/\/(www\.)?twitter\.com\/explore(\?|$).*/,
    /^https?:\/\/(www\.)?twitter\.com\/notifications(\?|$).*/,
    /^https?:\/\/(www\.)?twitter\.com\/messages(\?|$).*/,

    /^https?:\/\/(www\.)?youtube\.com\/?$/,
    /^https?:\/\/(www\.)?youtube\.com\/feed(\/|$).*/,
    /^https?:\/\/(www\.)?youtube\.com\/shorts(\/|$).*/,
    /^https?:\/\/(www\.)?youtube\.com\/results(\/|$).*/
  ];

  for (var i = 0; i < blockedUrlPatterns.length; i++) {
    if (blockedUrlPatterns[i].test(url)) {
      return "PROXY 127.0.0.1:9";
    }
  }

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
