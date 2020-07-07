# Deployment — details & procedures

This app *mostly* works as static pages, and I intend to keep it this way.
(To run simply open index.html.  Or fork on github and immediately use your gh-pages branch at https://YOUR-GITHUB-USERNAME.github.io/mathdown/.  See top-level README.md.)

But for HTTPS on custom domain and some future features, I've switched to a Node.js server and the main hosting to ~~RHcloud aka Openshift Online v2~~; then Openshift v2 was sunset; the kubernetes-based Openshift Online v3 pricing is not friendly to small apps, so now using Heroku.

Run as a dynamic app (`server.coffee`):

    npm install  # once
    env PORT=8001 npm start  # Prints URL you can click

(you can choose any port of course.  <kbd>Ctrl+C</kbd> when done.)

To deploy use `deployment/deploy.sh` (aka `npm run deploy`).
It first pushes to staging copies of the app:
https://mathdown-staging.herokuapp.com
then runs the test against those copies, and only then deploys the real Heroku apps.

## Heroku

There is also a deployment at https://mathdown.herokuapp.com/.  To deploy:

    heroku login  # Once per computer

    deployment/git-remotes.sh
    # Don't run this directly - use deployment/deploy.sh
    git push heroku gh-pages:master

(Heroku have an option to automatically deploy from github but that [doesn't support submodules](https://github.com/cben/mathdown/issues/57#issuecomment-74395026).)

Admin: https://dashboard.heroku.com/apps/mathdown
("Activity" tab shows history of deploys.)

I'm on "Hobby" $7/mo plan => 1 dyno, custom domain SSL, no idling.

mathdown-staging.herokuapp.com is on Free plan ([dyno sleeps][] after a 30min without traffic, takes ~10sec to wake up, limited to **max 18hrs/day**).

[dyno sleeps]: https://devcenter.heroku.com/articles/dyno-sleeping

Read logs:

    heroku logs

Performance (I installed various addons but haven't really instrumented anything):

- https://log2viz.herokuapp.com/app/mathdown (last 60 second of logs)
  See https://blog.heroku.com/archives/2013/3/19/log2viz for background.
- https://metrics.librato.com/dashboards/67753?duration=3600
- https://www.hostedgraphite.com/cf9c6211/grafana/#/dashboard/elasticsearch/Heroku
- https://strongops.strongloop.com/ops/dashboard
- https://heroku.nodetime.com/sso/login
- https://www.blitz.io/to#/dashboard/rush

### SSL on Heroku

https://devcenter.heroku.com/articles/ssl

> TODO: update - easier with Let's Encrypt giving 1 cert for all 4 domains.

The wildcard `*.herokuapp.com` cert for https://mathdown.herokuapp.com/ and https://mathdown-staging.herokuapp.com always works.

For custom domains, apps with paid dynos (including my Hobby plan) can upload certs or even free automated cert provisioning by Heroku.
I tried automated provisioning but it requires DNS to point to Heroku, so doesn't allow zero-downtime switching between heroku and other places.

So I stayed with getting certs from Let's Encrypt myself and uploading to Heroku (also included with any paid dynos, including my Hobby plan).
Cert config is not in the via web dashboard at all (AFAICT).  To see status:

    heroku certs:info --app=mathdown

This tells you the "SSL Endpoint", currently osaka-3545.herokussl.com, that DNS must point to (*not* mathdown.herokuapp.com!).

Provisioning the cert:

    deployment/tls-certs-letsencrypt/heroku-set-certs.sh

## HTTPS (TLS/SSL) certificates

I'm getting free certificates from [Let's Encrypt][] based on [Jason Kulatunga's tutorial][].

To obtain new certs:

    # get token from https://dnsimple.com/user
    env LEXICON_DNSIMPLE_USERNAME=beni.cherniavsky \
        LEXICON_DNSIMPLE_TOKEN=... \
        tls-certs-letsencrypt/obtain-certs.sh

The certs are under `tls-certs-letsencrypt/certs/` subdirectory (non-secret parts in git).
To inspect the certs, including **expiration date**, run `tls-certs-letsencrypt/show-cert.sh`.

Note: Heroku, as any reasonably priced hosting that doesn't give dedicated IPv4, can only support custom-domain certs with SNI (client sending requested host during TLS handshake).  The main group this leaves in the dark is Android 2.x default browser, and IE8 on XP.

[Jason Kulatunga's tutorial]: http://blog.thesparktree.com/post/138999997429/generating-intranet-and-private-network-ssl
[Let's Encrypt]: https://letsencrypt.org/

## DNS

mathdown.net and mathdown.com domains are registered at https://www.gandi.net/ (expire 2019 Sep 10).

Using an apex domain (with www. subdomain) turned out to be a pain, so while I'll keep them working, I'm redirecting to www.mathdown.net as the canonical URL.

  - Can't do normal CNAME; [some DNS providers][] can simulate it, notably [Cloudflare claim to have done it well][] (and free unlike DNSimple).
  - Without CNAME, Github Pages do provide fixed IPs that are slower ([extra 302 redirect][]).
  - Without CNAME, ~~Heroku can't work at all~~!

~~That's why DNS was served by Cloudflare (free plan, just DNS "bypassing" their CDN).~~
**Alas, Cloudflare served the apex mathdown.{net,com} with a TTL of 7 days**, which means a long outage for some users when the server IP changes [https://github.com/cben/mathdown/issues/104].  UPDATE 2016-10: a CloudFlare engineer wrote back saying they fixed something so this might work fine now.

I've switched to DNSimple as my DNS, with TTL of 1-10min.
mathdown.net, www.mathdown.net, mathdown.com, www.mathdown.com currently all point at Heroku.

Quick way to download current DNSimple settings (in a logged-in browser):
https://dnsimple.com/domains/mathdown.net/zone.txt
https://dnsimple.com/domains/mathdown.com/zone.txt

[some DNS providers]: https://devcenter.heroku.com/articles/custom-domains#root-domain
[Cloudflare claim to have done it well]: https://blog.cloudflare.com/introducing-cname-flattening-rfc-compliant-cnames-at-a-domains-root/
[extra 302 redirect]: https://news.ycombinator.com/item?id=7738293

## TODO: Monitoring/alerting [#78](https://github.com/cben/mathdown/issues/78)

Extremely rudimentary monitoring at

- Pingdom: [private](https://my.pingdom.com/dashboard/checks) — public summary at http://stats.pingdom.com/imb1lncuugx2
  Only checks that https://mathdown.net/ responds & includes the string "MathJax".
  On errors it provides useful details (Reports => Uptime Reports) - IP tried, traceroute, full HTTP exchange.
  Free plan will disappear in 2017.

- UptimeRobot: [private dashboard](https://uptimerobot.com/dashboard), [public RSS link](http://rss.uptimerobot.com/u161856-2938762f077934131eb64592ffd2e8f9).  [Handy Chrome extension (needs private API key)](http://shreyaspurohit.github.io/chrome.extension.uptimeRobotMonitor/).
  Checks that https://{www.,}mathdown.{net,com}, http://mathdown.net, and directly accessed rhcloud, heroku, gh-pages respond.  No details if they don't.

- StatusCake WIP.
  Unlimited free checks, doesn't think my redirects are down.
  Private dashboard: https://www.statuscake.com/App/YourStatus.php
  Public dashboard: http://uptime.statuscake.com/?TestID=Q28S2gZ42e
  Monthly uptime: ![StatusCake uptime](https://www.statuscake.com/App/button/index.php?Track=UFzBR9YWzA&Days=30&Design=1)

If the server is down I will get mails, but I'm not tracking server-side load/error, especially on RHcloud.

> TODO: I had expired TLS cert for about a day this summer, and I don't think any of these 3 monitoring services reported downtime?!

My Firebase usage graph: https://console.firebase.google.com/u/0/project/firebase-mathdown/database/usage
Firebase uptime: http://status.firebase.com/ (as of May 2015 my data is on [s-dal5-nss-33](http://status.firebase.com/1502938) but could move).

Heroku status: https://status.heroku.com/
