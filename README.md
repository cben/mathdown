http://mathdown.net
===================

[![Travis test runner](https://img.shields.io/travis/cben/mathdown.svg?label=test)](https://travis-ci.org/cben/mathdown/branches)
[![Saucelabs browser tests](https://saucelabs.com/browser-matrix/mathdown.svg)](https://saucelabs.com/users/mathdown/tests)

Collaborative markdown with math.
Powered by [CodeMirror][], [MathJax][] and [Firebase][]'s [Firepad][].
Free testing [courtesy of Sause Labs](https://saucelabs.com/opensauce).

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
  * Firebase is a **proprietary** service ([#4](https://github.com/cben/mathdown/issues/4)); their client-side javascipt API [firebase.js][] was [accidentally MIT-licensed for a time but is now proprietary](https://groups.google.com/forum/#!topic/firebase-talk/pAklVV3Whw8).
  * The collaborative editor [Firepad] is MIT.  It calls firebase javascipt API.

## Git trivia

After checking out, run this to materialize subdirs://

    git submodule update --init --recursive

Append ` --remote` to upgrade to newest versions of all submodules (need to commit afterwards if anything changed).  However we can't update all deps:

  * firebase beyond v1.0.21 is not FOSS-licensed.  Until that it was MIT by mistake but pinning at v1.0.21
    seems better for a short time — long term it's unhealthy as their wire protocol evolves...
  * firepad only includes pre-built dist/firepad.js in tagged versions since v1.0.0.
    E.g. v1.1.0 would work, but it declares dependency on firebase 2.0.x, so for now firepad v1.0.0 seems safer.

I'm directly working in `gh-pages` branch without a `master` branch, as that's the simplest thing that could possibly work (http://oli.jp/2011/github-pages-workflow/ lists several alternatives).

## Where it's deployed and how to run your fork

This app *mostly* works as static pages, and I intend to keep it this way.

  * You can run locally - just open index.html.

  * Github Pages serves the gh-pages branch at https://cben.github.io/mathdown.
    Currently this also serves http://mathdown.net and http://www.mathdown.net but unfortunately this doesn't support HTTPS (#4).

      * If you fork this repo, you can immediately use your version at https://YOUR-GITHUB-USERNAME.github.io/mathdown/!

(For other branches/commits, there is no trivial solution - rawgit.com doesn't currently support submodules.)

However you run it, you can open the same document ids and real-time collaboration works.

The only benefits a dynamic server is going to bring (not implement yet) are:

 1. Including the document text in the HTTP response for search engines (#7).
 2. Prettier `mathdown.net/foobar` instead of `mathdown.net/?doc=foobar` URLs (#59).

I'm testing hosting on Heroku (https://mathdown.herokuapp.com, should auto-deploy from `gh-pages` on github) and Openshift.
Heroku Button for forks is very neat!
Both require $20/month for TLS on custom domain; while I understand why that's an effective threshold for "serious" customers to pay, but it annoys me engineering-wise (shared cert TLS is not significantly cheaper for them than custom cert).  Also, upgrading to Openshift bronze failed so far.
Looking into Cloudflare to front the custom domain...

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
