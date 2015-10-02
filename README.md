https://www.mathdown.net
========================

## ⚠ Currently mathdown.net may be inaccessible due to DNS issues (#104).  Use *www.*mathdown.net.

Collaborative markdown with math.  Main features:

- Markdown is styled in-place, no source/preview separation.
- Edits are synced in real time.
- Access control is simply by sharing the secret URL.  No sign up needed to collaborate.
- LaTeX-syntax formulas rendered in-place when cursor is outside formula.

Powered by [CodeMirror][], [MathJax][] and [Firebase][]'s [Firepad][].
I'm using "CM" = CodeMirror, "MJ" = MathJax abbreviations a lot in the project.

[CodeMirror]: https://codemirror.net
[MathJax]: https://www.mathjax.org
[Firebase]: https://firebase.com
[Firepad]: http://firepad.io
[CodeMirror-MathJax]: https://github.com/cben/CodeMirror-MathJax
[firebase.js]: https://github.com/firebase/firebase-bower

**Alpha quality – will eat your math, burn your bookmarks & expose your secrets.**
I mean it.  See for example [#85](https://github.com/cben/mathdown/issues/4) — saving would sometimes be silently broken, for *half a year*!  I'm working to make it more robust (and tested) but for now, be careful.

Issues:
[![mathdown HuBoard](https://img.shields.io/github/issues/cben/mathdown.svg?label=mathdown%20(HuBoard))](https://huboard.com/cben/mathdown)
[![CodeMirror-MathJax issues](https://img.shields.io/github/issues/cben/CodeMirror-MathJax.svg?label=CodeMirror-MathJax)](https://github.com/cben/CodeMirror-MathJax/issues)

## License

My code is under [MIT License](LICENSE).

Dependencies:

  * CodeMirror is also MIT.
  * MathJax is under Apache License 2.0.
  * My [CodeMirror-MathJax][] glue is also MIT.
  * The collaborative editor [Firepad] is MIT.  It calls firebase javascipt API.
  * Firebase is a **proprietary** service; their client-side javascipt API [firebase.js][] is also [proprietary](https://www.firebase.com/terms/terms-of-service.html), though apparently fine to distribute in practice — ([#4](https://github.com/cben/mathdown/issues/4)).
    [firbease.js has been [accidentally MIT-licensed for a time](https://groups.google.com/forum/#!topic/firebase-talk/pAklVV3Whw8) but I've upgraded to newer versions so this doesn't apply.]

    I'm not including firebase.js directly but using it as a git submodule.

## Document hosting and privacy(?) on Firebase

All user data is stored in Firebase, now owned by Google.  [Their privacy policy](https://www.firebase.com/terms/privacy-policy.html).
Documents access (read AND edit) is by secret document id which is part of the url.  This is grossly unsecure unless using HTTPS.

The downside is users can't really control their data.  Running a "self-hosted" copy of the site still leaves all data in the hands of Firebase.  See #4 for more discussion.

The upside is all forks interoperate; you can change the design or tweak the editor and still access same documents.  E.g. https://mathdown.net/index.html?doc=demo and http://rhythmus.be/mathdown/index.html?doc=demo look different but access the same doc -- and real-time collaboration between them works!

I'm so far on the [free Firebase plan](https://www.firebase.com/pricing.html) - 100 devices (not sure if 1:1 with users), 1GB Data Storage (used < 100MB).  => Will need 49USD/mo plan as soon as I get non-negligible usage.
https://mathdown.firebaseio.com/?page=Analytics (only visible to me)

### Deletion is impossible

The current Firebase security rules make document history append-only.  That's a nice safety feature but it means that once a document's URL gets out, it's full history is forever accessible to the the world.  This must change eventually ([#92](https://github.com/cben/mathdown/issues/92)).

## Browser support

Basically whatever CodeMirror supports: IE8+ and about everything else.
But mobile is currently almost unusable ([#81](https://github.com/cben/mathdown/issues/81)).

**JavaScript is required** (and this includes running the non-Free firebase.js in your browser).
You can't even read documents without JavaScript; reading won't be hard to fix ([#7](https://github.com/cben/mathdown/issues/7)) — but editing documents without JavaScript is implausible (I plan to settle for append-only form).

### Cookies

The only cookies I'm aware of:

  - `GEAR` session cookie set by OpenShift hosting (I presume for server stickiness, which I don't actually need).
  - `mjx.menu` cookie set for a year(?) if you manually change MathJax settings.

I'm not sure Firebase never sets cookies.  Things will change once I implement login (#50).

## Installing dependencies

[![Dependency Status](https://david-dm.org/cben/mathdown.svg)](https://david-dm.org/cben/mathdown)
[![devDependency Status](https://david-dm.org/cben/mathdown/dev-status.svg)](https://david-dm.org/cben/mathdown#info=devDependencies)

 1. After checking out, run this to materialize client-side dependencies:

    git submodule update --init --recursive

  Append ` --remote` to upgrade to newest versions of all submodules (need to commit afterwards if anything changed).  Known constraints on updating all deps:

    * firepad only includes pre-built dist/firepad.js in tagged versions (after every release they strip it back).
    * [CodeMirror-MathJax currently doesn't support MathJax 2.5](https://github.com/cben/CodeMirror-MathJax/issues/33).

  (I'm directly working in `gh-pages` branch without a `master` branch.  GH Pages automatically resolves https://... submodules.  It's no longer the primary hosting but it's still useful to test the static version works.)

 2. To install server-side dependencies (and devDependencies) listed in `package.json` run:

        npm install

  (But when deploying to RHcloud or Heroku, npm install might run in `--production` mode and devDependencies won't be available.)

  To see whether any updates are needed/possible, run `npm outdated`.  To update run:

    npm update --save
    npm shrinkwrap

    Then commit the new `package.json` and `npm-shrinkwrap.json`.
  TODO: find way to use same **node.js version** in dev and prod?


## Test(s)

[![Travis test runner](https://img.shields.io/travis/cben/mathdown.svg?label=test)](https://travis-ci.org/cben/mathdown/branches)
[![Saucelabs browser tests](https://saucelabs.com/browser-matrix/mathdown.svg)](https://saucelabs.com/users/mathdown/tests)

`test/browser-on-saucelabs.spec.coffee` runs tests on several browsers using free browser testing [courtesy of Sause Labs](https://saucelabs.com/opensauce).
There are pathetically few tests.

To run the tests:

    npm install  # once
    npm test

To run only some tests and/or browsers, use:

    ./node_modules/.bin/mocha --grep firefox

The test runs automatically on any commit and pull request.
I've tried several free services for this, and currently prefer Travis:

  * [Travis](https://travis-ci.org/cben/mathdown/branches) - works, open source code.  Controlled by `.travis.yml`.
  * [Drone](https://drone.io/github.com/cben/mathdown) - Docker-based, [open source](https://github.com/drone/drone) rewrite in progress.  Alas, always times out during test.  Test config on the web.
  * [Shippable](https://app.shippable.com/projects/54b58b855ab6cc13528881c1) - builds history only accessible by me?  Bad, I want public.  Controlled by `.travis.yml`.
  * [Codeship](https://codeship.com/projects/17706) - same, dashboard is private.  Test config on the web.
  * [Wercker](https://app.wercker.com/#applications/54b6c5a2d9b237dd37003402) - same, dashboard is private.  Controlled by `wercker.yml`.

## Where it's deployed and how to run your fork

The main deployment runs on https://mathdown-cben.rhcloud.com/ (Openshift hosting operated by RedHat), and mathdown.net points to it.  The dynamic server has also been tested on Heroku.  See [deployment/](deployment/) subdirectory for details.

**However you run it, you can open the same document ids (`doc=...`) and real-time collaboration will work!**

Quick ways to run:

[![Launch on OpenShift](https://launch-shifter.rhcloud.com/launch/LAUNCH ON.svg)](https://openshift.redhat.com/app/console/application_type/custom?&cartridges[]=nodejs-0.10&initial_git_url=https://github.com/cben/mathdown.git&initial_git_branch=gh-pages&name=mathdown) — make sure to replace with your fork & branch as needed.  Don't enable scaling without reading "Creating an app" in [deployment/README.md](deployment/README.md).  Grab a tea - takes up to 10 minutes.  (Remember it'll not auto-update, it'll be up to you to git push newer versions...)

Deploy on Heroku:

	heroku create my-mathdown --remote heroku-my-mathdown
	git push heroku-my-mathdown gh-pages:master

Run local server (`server.coffee`):

    npm install  # once
    env PORT=8001 npm start  # Prints URL you can click

(you can choose any port of course.  <kbd>Ctrl+C</kbd> when done.)

This app *mostly* works as pure static pages, and I intend to keep it this way.

  * From a checkout, **just open `index.html` in your browser**.

  * Github Pages serves the gh-pages branch at https://cben.github.io/mathdown.
    Note that Github Pages is **insecure** (the HTTPS encryption is [not end-to-end][]),
    so your doc IDs could be snooped giving full read & edit access to your docs.

    [not end-to-end]: https://konklone.com/post/github-pages-now-sorta-supports-https-so-use-it#comment-54d648a969702d6be8110a00

      * If you fork this repo, you can immediately use your version at https://YOUR-GITHUB-USERNAME.github.io/mathdown/!
      Or maybe not immediately but [after you push something](http://stackoverflow.com/q/8587321/239657).
	  See above how it's **insecure**.

  * For other branches/commits, there is no trivial solution - rawgit.com would be great but doesn't currently support submodules.

  * The easiest way to run (and share) uncommitted modifications is probably Cloud 9.  TODO: test, details.

The only benefits the dynamic server is going to bring (not implemented yet) will be:

 1. Including the document text in the HTTP response for search engines (#7).
 2. Prettier `mathdown.net/foobar` instead of `mathdown.net/?doc=foobar` URLs (#59).

----

Other things called "mathdown":

 * https://github.com/mayoff/Mathdown/tree/mathjax — Markdown.pl hacked for MathJax pass-through
 * https://github.com/keishi/kernlog/blob/master/markdown/extensions/mathdown.py — math in python-markdown, part of "Yet another blog for google app engine"
 * http://kwkbtr.info/log/201010050320 — a way to combine Showdown + Mathjax
 * https://gitlab.com/padawanphysicist/tw5-mathdown/tree/master — Math (via TeXZilla) + Markdown-it in TiddlyWiki5
 * https://github.com/domluna/mathdown — Watches markdown files, converts to HTML with KateX.
 * https://github.com/jirkalewandowski/mathdown — heuristically recognizes LaTeX formulas in text with no delimiters.

I should really talk to these folk whether it's OK that I'm using the name and the domain...

 * http://www.urbandictionary.com/define.php?term=mathdown
