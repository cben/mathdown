http://mathdown.net
===================

![saucelabs test badge](https://saucelabs.com/browser-matrix/mathdown.svg)

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
 * Firebase is a **proprietary** service ([#4](https://github.com/cben/mathdown/issues/4)); their client-side javascipt API [firebase.js][] is MIT.
 * The collaborative editor [Firepad] is MIT.  It calls firebase javascipt API.

## Git trivia

After checking out, run this to materialize subdirs://

    git submodule update --init --recursive

Append ` --remote` to upgrade to newest versions of all submodules (need to commit afterwards if anything changed).

I'm directly working in gh-pages branch without a master branch, as that's the simplest thing that could possibly work (http://oli.jp/2011/github-pages-workflow/ lists several alternatives).

----

Other things called "mathdown":

 * https://github.com/mayoff/Mathdown/tree/mathjax — Markdown.pl hacked for MathJax pass-through
 * https://github.com/keishi/kernlog/blob/master/markdown/extensions/mathdown.py
 * http://kwkbtr.info/log/201010050320 — a way to combine Showdown + Mathjax.
 * http://www.urbandictionary.com/define.php?term=mathdown
