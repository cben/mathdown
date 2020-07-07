// This is a separate file so that I might reuse it client-side.

exports = exports || {};

// TODO: can all this somehow lead to leaking sensitive Referer to different site?

// TODO: educate user after http->https redirect with sensitive doc=...?

httpsDomainPatterns = [
    /\.herokuapp\.com$/,
    /\.rhcloud\.com$/,
    /\.github\.io$/,  // not end-to-end secure but better than nothing
    /^(.*\.)?mathdown\.net$/,
    /^(.*\.)?mathdown\.com$/
];

// TODO: HSTS (Strict Transport Security).
// Does it belong here, or only on non-redirecting responses?

canonicalDomains = {
  "mathdown.net": "www.mathdown.net",
  "mathdown.com": "www.mathdown.net",
  "www.mathdown.com": "www.mathdown.net"
};

// returns {status, headers} object or null if no redirect.
// headers is an object including at least {Location}.
exports.computeRedirect = function computeRedirect(method, protocol, host, path) {
  method = method.toUpperCase();
  protocol = protocol.toLowerCase();
  if(!host)
    return null;  // assuming I don't do any same-host redirects here.
  host = host.toLowerCase();

  var redir = false;
  var redirProtocol = false;  // if false, use protocol-relative location.

  if (host in canonicalDomains) {
    redir = true;
    host = canonicalDomains[host];
  }
  // Use HTTPS if supported by target [canonical] domain.
  if (protocol == "http") {
    for (var i = 0; i < httpsDomainPatterns.length; i++) {
      if (httpsDomainPatterns[i].test(host)) {
	redir = true;
	redirProtocol = true;
	protocol = "https";
	break;
      }
    }
  }

  if (redir) {
    // 301 in some clients converts POST (and sometimes other methods) -> GET.
    // (We don't yet support any non-GET methods but let's do the right thing.)
    var status = (method == "GET" || method == "HEAD" ? 301 : 307);
    return {
      status: status,
      headers: {
	Location: (redirProtocol ? protocol + "://" : "//") + host + path,
	// Node.js doesn't by default send length (nor chunked encoding) for HEAD requests.
	// Browsers don't care but we SHOULD: http://stackoverflow.com/a/18925736.
	'Content-Length': 0
      }
    };
  } else {
    return null;
  }
}

// TODO: apply redirects when running in a browser.
// TODO: handle / -> /?doc=about here.
