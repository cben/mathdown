# Deployment — details & procedures

This app *mostly* works as static pages, and I intend to keep it this way.
(To run simply open index.html.  See top-level README.md.)

But for HTTPS on custom domain and some future features, I'm switching the main hosting to RHcloud.
Run as a dynamic app (`server.coffee`):

    npm install  # once
    env PORT=8001 npm start  # Prints URL you can click

(you can choose any port of course.  <kbd>Ctrl+C</kbd> when done.)

It should also be easy to run on Heroku (works as of writing this, not sure if I'll test this regularly).

## RHcloud (aka Openshift)

The main deployment runs on https://mathdown-cben.rhcloud.com/, and mathdown.{net,com} point to it (see DNS section).  To deploy:

    git remote add rhcloud	ssh://546a6d7e5973cac907000028@mathdown-cben.rhcloud.com/~/git/mathdown.git/  # once
    git push rhcloud gh-pages:master

(TODO: it's possible to configure pushes to gh-pages).

I'm on the Bronze plan (requires credit card but starts at $0), which allows me: no idling, custom domain TLS, paying several $/mo for [more quota][], option to scale beyond the 3 free machines ("gears").

[more quota]: https://github.com/cben/mathdown/issues/73

Admin: https://openshift.redhat.com/app/console/application/546a6d7e5973cac907000028-mathdown

Read logs:

    rhc tail mathdown -o '-n 100'  # runs tail -f -n 100

Ssh directly into the "gear":

    rhc ssh mathdown

or use direct command shown on admin page:

    ssh 546a6d7e5973cac907000028@mathdown-cben.rhcloud.com

Performance: TODO
Haproxy status at: http://mathdown-cben.rhcloud.com/haproxy-status/ but I have little idea how to read that...

Valuable Openshift tips: https://stackoverflow.com/questions/11730590/what-are-some-of-the-tricks-to-using-openshift

## Heroku

There is also a deployment at https://mathdown.herokuapp.com/.  To deploy:

    git remote add heroku https://git.heroku.com/mathdown.git  # once
    git push heroku gh-pages:master

(Heroku have an option to automatically deploy from github but that [doesn't support submodules](https://github.com/cben/mathdown/issues/57#issuecomment-74395026).)

I'm on free plan => 1 web dyno, with idling ([dyno sleeps][] after a hour without traffic, takes ~10sec to wake up), no custom-domain TLS.

[dyno sleeps]: https://blog.heroku.com/archives/2013/6/20/app_sleeping_on_heroku

Admin: https://dashboard.heroku.com/apps/mathdown

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

TODO: add deploy on heroku button.  Their 1-free-per-*app* model is perfect for contributors.

## TODO: staging, continuous integration->deploy

Currently CI runs tests against temp locally server and I must manually deploy to RHcloud/Heroku.
It should be easy to config auto-deploy.

What's more important would be testing that it works on RHcloud/Heroku: adding a separate "staging" app, deploying to it first, testing that it works in prod, only then deploying to main app. (#77)

## HTTPS (TLS/SSL) certificates

I got free certificates from [StartCom][] following [Eric Mill's tutorial][] for:

- www.mathdown.com & mathdown.com (expires 2016 Feb 12)
- www.mathdown.net & mathdown.net (expires 2016 Feb 15)

(Class 1 Validation, sha256WithRSAEncryption signature, 2048 bit key).

The non-secret files are in this directory.

Note: Both RHcloud and Heroku can only support custom-domain certs with SNI (client sending requested host during TLS handshake).  The main group this leaves in the dark is Android 2.x default browser, and IE8 on XP.

[Eric Mill's tutorial]: https://konklone.com/post/switch-to-https-now-for-free
[StartCom]: https://StartSSL.com

Configuring the domains and certs on RHcloud can be repeated with `tls-certs-startcom/rhc-set-certs.sh` script.

## DNS

mathdown.net and mathdown.com domains are registered at https://www.gandi.net/ (expire 2016 Sep 10).

Using an apex domain (with www. subdomain) turns out to be a pain, but I'm sticking with it for now.

  - Can't do normal CNAME; [some DNS providers][] can simulate it, notably [Cloudflare claim to have done it well][] (and free unlike dnssimple.
  - Without CNAME, Github Pages do provide fixed IPs that are slower ([extra 302 redirect][]).
  - Without CNAME, Heroku can't work at all!

That's why DNS is served by Cloudflare (free plan).
mathdown.net, www.mathdown.net, mathdown.com, www.mathdown.com all point at RHcloud.

Giving them control of my DNS does give them the ability to take over my site, acting as man-in-the-middle (as a CDN wants to do), including minting certificates for my domain.
Technically that's true for anyone serving my DNS, and I trust them.  See discussion at https://github.com/cben/mathdown/issues/6#issuecomment-74223153.

Anyway I'm currently keeping Cloudflare's CDN abilities disabled (grey "bypass" icon).

[some DNS providers]: https://devcenter.heroku.com/articles/custom-domains#root-domain
[Cloudflare claim to have done it well]: https://blog.cloudflare.com/introducing-cname-flattening-rfc-compliant-cnames-at-a-domains-root/
[extra 302 redirect]: https://news.ycombinator.com/item?id=7738293
