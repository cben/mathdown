# Deployment — details & procedures

This app *mostly* works as static pages, and I intend to keep it this way.
(To run simply open index.html.  Or fork on github and immediately use your gh-pages branch at https://YOUR-GITHUB-USERNAME.github.io/mathdown/.  See top-level README.md.)

But for HTTPS on custom domain and some future features, I've switched to a Node.js server and the main hosting to RHcloud.

Run as a dynamic app (`server.coffee`):

    npm install  # once
    env PORT=8001 npm start  # Prints URL you can click

(you can choose any port of course.  <kbd>Ctrl+C</kbd> when done.)

To deploy use `deployment/deploy.sh` (aka `npm run deploy`).
It first pushes to staging copies of the app:
https://mathdown-staging.herokuapp.com
https://staging-mathdown.rhcloud.com
then runs the test against those copies, and only then deploys the real Rhcloud & Heroku apps.

## RHcloud (aka Openshift)

[Tip: the exact app (`prod -n mathdown` below) can be omitted from all `rhc` commands if git config `rhc.*` are set.  See "Creating an app" below.]

The main deployment runs on https://prod-mathdown.rhcloud.com/, and mathdown.{net,com} point to it (see DNS section).  To deploy:

    # Don't run this directly - use deployment/deploy.sh
    git push rhcloud gh-pages:master

(it's possible to configure pushes to `gh-pages`, but I'm keeping the default `master` for least customization and consistency with heroku).

Deployments history is not exposed in UI, can be recovered from reflog:

    rhc ssh prod -n mathdown 'cd git/mathdown.git; git log --walk-reflogs master --date=local --pretty=short'

**Do not interrupt git push**.  Once I did that and the app was not updated, one of the gears stayed down (haproxy showed "MAINT" state) but git itself was up to date so repeating git push was a no-op.

I'm on the Bronze plan (requires credit card but starts at $0), which allows me: no idling, custom domain TLS, paying several $/mo for [more quota][], option to scale beyond the 3 free `small` machines ("gears").

[more quota]: https://github.com/cben/mathdown/issues/73

Admin: https://openshift.redhat.com/app/console/application/546a6d7e5973cac907000028-mathdown

Read logs [[more info](https://developers.openshift.com/en/managing-log-files.html)]:

    rhc ssh prod -n mathdown --gears 'cd app-root/logs/; ls -ltr; tail -f -n 100 *.log'

    # To download them all locally:
    for GEAR_AT_HOST in $(rhc show-app prod -n mathdown --gears=ssh); do
      rsync -r $GEAR_AT_HOST:app-root/logs/ logs-$(date -I)-gear-$GEAR_AT_HOST/
    done

SSH directly into the main "gear":

    rhc ssh prod -n mathdown

or use direct command as shown on admin page.

Other gears are similarly accessible by direct SSH but you need to check the host names:

    rhc show-app prod -n mathdown --gears

Performance: TODO

Haproxy status at: http://prod-mathdown.rhcloud.com/haproxy-status/

Haproxy config is at `haproxy/conf/haproxy.cfg` under home dir on first gear.
Source seems to be at https://github.com/openshift/origin-server/blob/master/cartridges/openshift-origin-cartridge-haproxy/versions/1.4/configuration/haproxy.cfg.erb

Valuable Openshift tips: https://stackoverflow.com/questions/11730590/what-are-some-of-the-tricks-to-using-openshift

### Creating an app: scaling, gear size, timeouts, Jenkins

The prod app should **always** be a scaling app (which means it includes Haproxy and can have >1 machines).  It should have at least 2 gears — this allows zero-downtime deploys (one gear goes down, then the other).  There is no way to turn an unscaled app to a scaled one except destroying and re-creating.
What's worse, there is [no way to flip traffic to a new app without downtime][].

[no way to flip traffic to a new app without downtime]: https://openshift.uservoice.com/forums/258655-ideas/suggestions/6705869-make-it-possible-to-deploy-more-than-one-version-o

At some points the builds became slow enough that I'm hitting timeouts creating it from scratch (5min timeout) and even pushing new versions (2min I think?).
See [#115](https://github.com/cben/mathdown/issues/115) for the gory details.

Known solutions:

  - This only happens (so far) with `--scaling` enabled.  Unscaled apps build fast enough.
    Unscaled is probably OK for someone running a different/forked version.
  - Create from an old "working" version (468cf5aaf3 seems to work), then push the current.  Unreliable.  Bleh.
	  - However, creating an *empty* app (no `--from-code`), then doing `push -f` seems to work nicely.
  - Use beefier gears, e.g. `rhc create ... --scaling --gear-size small.highcpu`.
    There is no way to change gear size later except destroying and re-creating the app.
    `small.highcpu` times 2 gears costs $36/mo.
  - Offload builds to [Jenkins][]?  Builds are even slower, but are less on the critical path to timeout.  Unreliable.

Note that when `rhc app create` tells you timed out, sometimes the app still gets created!

[Jenkins]: https://developers.openshift.com/en/managing-continuous-integration.html

As of these writing, I've used these procedures (it's useful to timestamp by piping to `| ts -s` from moreutils):

    rhc setup  # Once per computer

    rhc app create -a staging -n mathdown -t nodejs-0.10 --scaling --debug --trace
    rm ./staging -rf

    rhc app create -a prod -n mathdown --from-code https://github.com/cben/mathdown\#gh-pages -t nodejs-0.10 --scaling --gear-size small.highcpu --debug --trace
    rhc cartridge storage nodejs-0.10 -a prod -n mathdown --set 1gb  # additional, 2gb total.
    rhc cartridge scale nodejs-0.10 -a prod -n mathdown --min 2 --max 5 --debug --trace

    # Configure rhc commands that don't specify an app to access the prod app:
    git config -f prod/.git/config --get-regexp '^rhc\.' | xargs -n 2 git config
    rm ./prod -rf

    # See https://github.com/openshift/rhc/issues/513 about making the above less awkward.

    deployment/git-remotes.sh
    git push -f rhcloud-staging gh-pages:master
    git push -f rhcloud gh-pages:master

    ./deployment/tls-certs-startcom/rhc-set-certs.sh 'prod -n mathdown' ~/StartSSL/my-private-decrypted.key

> TODO: re-test, update the above.

## Heroku

The primary reason Heroku is not my main hosting (beyond open source allegiance) is SSL (see below).

There is also a deployment at https://mathdown.herokuapp.com/.  To deploy:

    heroku login  # Once per computer

    deployment/git-remotes.sh
    # Don't run this directly - use deployment/deploy.sh
    git push heroku gh-pages:master

(Heroku have an option to automatically deploy from github but that [doesn't support submodules](https://github.com/cben/mathdown/issues/57#issuecomment-74395026).)

Admin: https://dashboard.heroku.com/apps/mathdown
("Activity" tab shows history of deploys.)

I'm on "Hobby" $7/mo plan => 1 dyno, no idling.
If I'm not serving mathdown.net all day, could run fine on Free plan ([dyno sleeps][] after a 30min without traffic, takes ~10sec to wake up, limited to **max 18hrs/day**).

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

> TODO: update - easier with Let's Encrypt giving 1 cert for all 4 domains.

The wildcard cert on https://mathdown.herokuapp.com/ is free.
For custom domain cert, Heroku charges $20/mo for the [SSL addon][] and it only accepts *one* cert.
Since I haven't bought a multi-domain cert for both .net and .com, I'd need $40/mo and [hackish config](http://stackoverflow.com/a/18982770/239657).

=> I've provisioned the .net cert on Heroku so I can sometimes direct traffic there.
.com must stay on RHcloud.  But .com doesn't officially exist.

Cert config is not in the via web dashboard at all (AFAICT).  To see status:

    heroku certs:info --app=mathdown

This tells you the "SSL Endpoint", currently osaka-3545.herokussl.com, that DNS must point to (*not* mathdown.herokuapp.com!).

Provisioning the cert:

    # only I have ~/StartSSL/, it can't go under git
    openssl rsa -in ~/StartSSL/my-private-encrypted.key -out ~/StartSSL/my-private-decrypted.key
    heroku certs:update --app=mathdown deployment/tls-certs-startcom/GENERATED-CHAINED-mathdown.net.pem  ~/StartSSL/my-private-decrypted.key
	rm ~/StartSSL/my-private-decrypted.key

[SSL addon]: https://devcenter.heroku.com/articles/ssl-endpoint

## HTTPS (TLS/SSL) certificates

> TODO: UPDATE

I got free certificates from [Let's Encrypt][] based on [Jason Kulatunga's tutorial][] for:

- www.mathdown.com & mathdown.com (expires 2016 Feb 12)
- www.mathdown.net & mathdown.net (expires 2016 Feb 15)

(Class 1 Validation, sha256WithRSAEncryption signature, 2048 bit key).

The non-secret files are in this directory.

Note: Both RHcloud and Heroku can only support custom-domain certs with SNI (client sending requested host during TLS handshake).  The main group this leaves in the dark is Android 2.x default browser, and IE8 on XP.

[Jason Kulatunga's tutorial]: http://blog.thesparktree.com/post/138999997429/generating-intranet-and-private-network-ssl
[Let's Encrypt]: https://letsencrypt.org/

Configuring the domains and certs on RHcloud can be repeated with `tls-certs-letsencrypt/rhc-set-certs.sh` script.

P.S. [Tip to inspect a chained (concatenated) certs file](http://comments.gmane.org/gmane.comp.encryption.openssl.user/43587):

    openssl crl2pkcs7 -nocrl -certfile fullchain.pem | openssl pkcs7 -print_certs -text

## DNS

mathdown.net and mathdown.com domains are registered at https://www.gandi.net/ (expire 2016 Sep 10).

Using an apex domain (with www. subdomain) turns out to be a pain, but I'm ~~sticking with it for now(?)~~.

  - Can't do normal CNAME; [some DNS providers][] can simulate it, notably [Cloudflare claim to have done it well][] (and free unlike DNSimple).
  - Without CNAME, Github Pages do provide fixed IPs that are slower ([extra 302 redirect][]).
  - Without CNAME, Heroku can't work at all!

~~That's why DNS was served by Cloudflare (free plan, just DNS "bypassing" their CDN).~~
**Alas, Cloudflare serves the apex mathdown.{net,com} with a TTL of 7 days**, which means a long outage for some users when the server IP changes [https://github.com/cben/mathdown/issues/104].
I've switched to DNSimple as my DNS, with TTL of 1-10min.
mathdown.net, www.mathdown.net, mathdown.com, www.mathdown.com usually all point at RHcloud, though .net may be shunted to Heroku sometimes.

I ~~also might~~ have switched back to `www.mathdown.net` as the primary domain.
> TODO: UPDATE

Quick way to download current DNSimple settings (in a logged-in browser):
https://dnsimple.com/domains/mathdown.net/zone.txt
https://dnsimple.com/domains/mathdown.com/zone.txt

[some DNS providers]: https://devcenter.heroku.com/articles/custom-domains#root-domain
[Cloudflare claim to have done it well]: https://blog.cloudflare.com/introducing-cname-flattening-rfc-compliant-cnames-at-a-domains-root/
[extra 302 redirect]: https://news.ycombinator.com/item?id=7738293

## TODO: Monitoring/alerting [#78](https://github.com/cben/mathdown/issues/78)

<a href="https://www.statuscake.com" title="Website Uptime Monitoring"><img src="" /></a>

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

TODO: I had expired TLS cert for about a day this summer, and I don't think any of these 3 monitoring services reported downtime?!

My Firebase usage graph: https://mathdown.firebaseio.com/?page=Analytics
Firebase uptime: http://status.firebase.com/ (as of May 2015 my data is on [s-dal5-nss-33](http://status.firebase.com/1502938) but could move).

OpenShift status: https://openshift.redhat.com/app/status/ but more details on twitter: https://twitter.com/openshift_ops
