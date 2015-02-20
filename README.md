https://mathdown.net
====================

Collaborative markdown with math.
Powered by [CodeMirror][], [MathJax][] and [Firebase][]'s [Firepad][].

[CodeMirror]: https://codemirror.net
[MathJax]: https://www.mathjax.org
[Firebase]: https://firebase.com
[Firepad]: http://firepad.io
[CodeMirror-MathJax]: https://github.com/cben/CodeMirror-MathJax
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
Documents access (read AND edit) is by secret document id which is part of the url.  This is grossly unsecure unless using HTTPS.

The downside is users can't really control their data.  Running a "self-hosted" copy of the site still leaves all data in the hands of Firebase.  See #4 for more discussion.

The upside is all forks interoperate; you can change the design or tweak the editor and still access same documents.  E.g. https://mathdown.net/index.html?doc=demo and http://rhythmus.be/mathdown/index.html?doc=demo look different but access the same doc -- and real-time collaboration between them works!

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

I'm directly working in `gh-pages` branch without a `master` branch.  GH Pages is no longer the primary hosting but it's still useful to test the static version works.

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

The main deployment runs on https://mathdown-cben.rhcloud.com/ (Openshift hosting operated by RedHat), and mathdown.net points to it.  The dynamic server has also been tested on Heroku.  See [deployment/](deployment/README.md) subdirectory for details.

This app *mostly* works as static pages, and I intend to keep it this way.

  * You can run locally - just open `index.html`.

  * Github Pages serves the gh-pages branch at https://cben.github.io/mathdown.

      * If you fork this repo, you can immediately use your version at https://YOUR-GITHUB-USERNAME.github.io/mathdown/!
        Or maybe not immediately but [after you push something](http://stackoverflow.com/q/8587321/239657).

        (For other branches/commits, there is no trivial solution - rawgit.com doesn't currently support submodules.)

        The easiest way to run (and share) uncommitted modifications is probably Cloud 9.  TODO: test, details.

As a dynamic app (`server.coffee`):

    npm install  # once
    env PORT=8001 npm start  # Prints URL you can click

(you can choose any port of course.  <kbd>Ctrl+C</kbd> when done.)

The only benefits the dynamic server is going to bring (not implemented yet) will be:

 1. Including the document text in the HTTP response for search engines (#7).
 2. Prettier `mathdown.net/foobar` instead of `mathdown.net/?doc=foobar` URLs (#59).

**However you run it, you can open the same document ids and real-time collaboration will work!**

----

Other things called "mathdown":

 * https://github.com/mayoff/Mathdown/tree/mathjax — Markdown.pl hacked for MathJax pass-through
 * https://github.com/keishi/kernlog/blob/master/markdown/extensions/mathdown.py - math in python-markdown, part of "Yet another blog for google app engine"
 * http://kwkbtr.info/log/201010050320 — a way to combine Showdown + Mathjax
 * https://gitlab.com/padawanphysicist/tw5-mathdown/tree/master - Math (via TeXZilla) + Markdown-it in TiddlyWiki5

I should really talk to these folk whether it's OK that I'm using the name and the domain... 

 * http://www.urbandictionary.com/define.php?term=mathdown
