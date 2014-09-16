# Mathdown

## Collaborative Markdown + math

### Demo

- <http://mathdown.net> (original)
- [http://rhythmus.be/mathdown](http://rhythmus.be/mathdown/?doc=K2b13TExFUJ#Mathdown) (redesign fork)
- [Einstein’s 1905 paper on special relativity](http://rhythmus.be/mathdown/?doc=NzbDnWwn2nF#Zur-Elektrodynamik-bewegter-K-rper)

---

ℹ **THIS REPO IS FORKED FROM [cben/mathdown](https://github.com/cben/mathdown).** [I](https://github.com/rhythmus) just did the redesign.

⚠ **Alpha quality! Will eat your math, burn your bookmarks & expose your secrets.**

:bug: **Known bugs are listed [here](http://rhythmus.be/mathdown/index.html?doc=DCJtdsxteYC#Mathdown-Bugs).**

![](http://rhythmus.be/mathdown/screengrab.gif)

![Typesetting special relativity in a web browser is delightful…](http://rhythmus.be/mathdown/delightful.png)](http://rhythmus.be/mathdown/index.html?doc=NzbDnWwn2nF#Zur-Elektrodynamik-bewegter-K-rper)

---

### Powered by

- [CodeMirror](http://codemirror.net), as the basis for wysiwyg editing in `contentEditable`;
- [MathJax](http://mathjax.org), for magical typesetting of LaTeX equations;
- glued by [CodeMirror-MathJax](http://github.com/cben/CodeMirror-MathJax);
- [Firebase](http://firebase.com)’s [Firepad](http://firepad.io), for real-time collaboration.
- Free testing courtesy of [Sause Labs](https://saucelabs.com/opensauce).


### License

- [@cben](https://github.com/cben)’s code (including [CodeMirror-MathJax](http://github.com/cben/CodeMirror-MathJax)) is under [MIT License](LICENSE).
- [My](https://github.com/rhythmus) css too.
- CodeMirror is also MIT.
- Firebase is a **proprietary** service ([#4](https://github.com/cben/mathdown/issues/4)); their client-side javascript API [firebase.js](https://github.com/firebase/firebase-bower) is MIT.
- The collaborative editor [Firepad](http://firepad.io) is MIT.  It calls firebase javascript API.


### Git trivia

After checking out, run this to materialize `subdirs://`

    git submodule update --init --recursive

Append ` --remote` to upgrade to newest versions of all submodules (need to commit afterwards if anything changed).

[@cben](https://github.com/cben) is directly working in the gh-pages branch without a master branch, as that’s the simplest thing that could possibly work (<http://oli.jp/2011/github-pages-workflow> lists several alternatives).

### Note

###### About the redesign
The redesign was inspired by [this discussion](https://github.com/quilljs/quill/issues/74#issuecomment-42942223), and as an experiment in search for how wysiwyg Markdown editing could look like.

###### Other things called “mathdown”

- https://github.com/mayoff/Mathdown/tree/mathjax — Markdown.pl hacked for MathJax pass-through
- https://github.com/keishi/kernlog/blob/master/markdown/extensions/mathdown.py
- http://kwkbtr.info/log/201010050320 — a way to combine Showdown + Mathjax
- http://www.urbandictionary.com/define.php?term=mathdown
