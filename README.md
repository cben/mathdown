http://mathdown.net
===================

Collaborative markdown with math.
Powered by [CodeMirror][], [MathJax][] and [Firebase][]'s [Firepad][].

[CodeMirror]: http://codemirror.net
[MathJax]: http://mathjax.org
[Firebase]: http://firebase.com
[Firepad]: http://firepad.io
[CodeMirror-MathJax]: http://github.com/cben/CodeMirror-MathJax
[firebase.js]: https://github.com/firebase/firebase-bower

**Alpha quality – will eat your math, burn your bookmarks & expose your secrets.**

## License

My code is under [MIT License](LICENSE).

Dependencies:

  * CodeMirror is also MIT.
  * MathJax is under Apache License 2.0.
  * My [CodeMirror-MathJax][] glue is also MIT.
  * Firebase is a **proprietary** service ([#4](https://github.com/cben/mathdown/issues/4)); their client-side javascipt API [firebase.js][] was [accidentally MIT-licensed for a time but is now proprietary](https://groups.google.com/forum/#!topic/firebase-talk/pAklVV3Whw8) (though gratis for almost any use) as are their APIs in other languages.
  * The collaborative editor [Firepad] is MIT.  It calls firebase javascipt API.

## Document hosting and privacy(?) on Firebase

All user data is stored in Firebase.  [Their privacy policy](https://www.firebase.com/terms/privacy-policy.html).
Documents access (read AND edit) is by secret document id which is part of the url.  **This is unsecure** as long as mathdown.net doesn't use HTTPS (#6)!

The downside is users can't really control their data.  Running a "self-hosted" copy of the site still leaves all data in the hands of Firebase.  See #4 for more discussion.

The upside is all forks interoperate; you can change the design or tweak the editor and still access same documents.  E.g. http://mathdown.net/index.html?doc=demo and http://rhythmus.be/mathdown/index.html?doc=demo look different but access the same doc -- and real-time collaboration between them works!

I'm so far on the [free Firebase plan](https://www.firebase.com/pricing.html) - 50 concurrent (not sure if 1:1 with users), 100 MB Data Storage (used more than half).  => Will need $49/mo plan as soon as I get non-negligible usage.
https://mathdown.firebaseio.com/?page=Analytics

## Git trivia

After checking out, run this to materialize subdirs://

    git submodule update --init --recursive

Append ` --remote` to upgrade to newest versions of all submodules (need to commit afterwards if anything changed).  However we can't update all deps:

  * firebase beyond v1.0.21 is not FOSS-licensed.  Until that it was MIT by mistake but pinning at v1.0.21
    seems better for a short time — long term it's unhealthy as their wire protocol evolves...
  * firepad only includes pre-built dist/firepad.js in tagged versions since v1.0.0.
    E.g. v1.1.0 would work, but it declares dependency on firebase 2.0.x, so for now firepad v1.0.0 seems safer.

I'm directly working in `gh-pages` branch without a `master` branch, as that's the simplest thing that could possibly work (http://oli.jp/2011/github-pages-workflow/ lists several alternatives).

## Test(s)

[![Travis test runner](https://img.shields.io/travis/cben/mathdown.svg?label=test)](https://travis-ci.org/cben/mathdown/branches)
[![Saucelabs browser tests](https://saucelabs.com/browser-matrix/mathdown.svg)](https://saucelabs.com/users/mathdown/tests)

It's pathetic, really.  `smoke-test.coffee` only checks the site loads, the title is set (which means the firepad loaded the document from firebase) and math got rendered.  And it only tests IE8 (well IE *is* fragile; I've managed to break the site completely on IE for a long time, at least twice).

This uses free browser testing [courtesy of Sause Labs](https://saucelabs.com/opensauce).

To run the test:

    npm install  # once
    npm test

The test runs automatically on any commit and pull request.
I've tried several free services for this, and currently prefer Travis:

  * [Travis](https://travis-ci.org/cben/mathdown/branches) - works, open source code.  Controlled by `.travis.yml`.
  * [Drone](https://drone.io/github.com/cben/mathdown) - Docker-based, [open source](https://github.com/drone/drone) rewrite in progress.  Alas, always times out during test.  Test config on the web.
  * [Shippable](https://app.shippable.com/projects/54b58b855ab6cc13528881c1) - builds history only accessible by me?  Bad, I want public.  Controlled by `.travis.yml`.
  * [Codeship](https://codeship.com/projects/17706) - same, dashboard is private.  Test config on the web.
  * [Wercker](https://app.wercker.com/#applications/54b6c5a2d9b237dd37003402) - same, dashboard is private.  Controlled by `wercker.yml`.

## Where it's deployed and how to run your fork

This app *mostly* works as static pages, and I intend to keep it this way.

  * You can run locally - just open `index.html`.

  * Github Pages serves the gh-pages branch at https://cben.github.io/mathdown.
    Currently this also serves http://mathdown.net and http://www.mathdown.net but unfortunately this doesn't support HTTPS (#4).

      * If you fork this repo, you can immediately use your version at https://YOUR-GITHUB-USERNAME.github.io/mathdown/!

(For other branches/commits, there is no trivial solution - rawgit.com doesn't currently support submodules.)

As a dynamic app (`server.coffee`):

    npm install  # once
    env PORT=8001 npm start  # Prints URL you can click

(you can choose any port of course.  <kbd>Ctrl+C</kbd> when done.)

The only benefits the dynamic server is going to bring (not implemented yet) are:

 1. Including the document text in the HTTP response for search engines (#7).
 2. Prettier `mathdown.net/foobar` instead of `mathdown.net/?doc=foobar` URLs (#59).

**However you run it, you can open the same document ids and real-time collaboration will work!**

I'm testing hosting on Heroku (https://mathdown.herokuapp.com, should auto-deploy from `gh-pages` on github) and Openshift (http://mathdown-cben.rhcloud.com/).
Heroku Button for forks is very neat!
Both require $20/month for TLS on custom domain; while I understand why that's an effective threshold for "serious" customers to pay, but it annoys me engineering-wise (shared cert TLS is not significantly cheaper for them than custom cert).  Also, upgrading to Openshift bronze failed so far.

### mathdown.net and mathdown.com domains

Registered at https://www.gandi.net/ and currently DNS-served by them.
Using an apex domain (with www. subdomain) turns out to be a pain, but I'm going to try.

  - Can't do normal CNAME; some DNS providers can simulate it, notably Cloudflare claim to have done it well.
  - Without CNAME, Github Pages do provide fixed IPs that are slower (extra 302 redirect).
  - Without CNAME, Heroku can't work at all!

I'm in process of getting free TLS certs from https://startssl.com.

The .com is currently a redirect to .net (served by Gandi), but I'm going play with it in various ways.

----

Other things called "mathdown":

 * https://github.com/mayoff/Mathdown/tree/mathjax — Markdown.pl hacked for MathJax pass-through
 * https://github.com/keishi/kernlog/blob/master/markdown/extensions/mathdown.py
 * http://kwkbtr.info/log/201010050320 — a way to combine Showdown + Mathjax.
 * http://www.urbandictionary.com/define.php?term=mathdown
