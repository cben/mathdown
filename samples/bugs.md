# Mathdown Bugs
#### cursor
- The cursor position is **very** buggy, due to how it’s implemented by CodeMirror.
- CodeMirror tracks the supposed position of the native cursor based on the line/character index, but assumes an equal advance-width of all characters (i.e. same monospace font), no margins, no paddings, no absolutely positioned elements, etc.
- In short: there is no direct relationship between the edited text and the rendered text; the mapping between DOM content and Visible content is [not well-behaved](https://medium.com/medium-eng/122d8a40e480).
- Firepad’s multiple cursors add up to the problem.
- If this is true, then we’re in great trouble to hack and mold CodeMirror into what we’re after: wysiwyg editing…
#### Performance
- MathJax webfonts load very slowly: this is especially noticeable on documents with lots of equations.

### Parsing
#### Emphasis
- When you have an isolated underscore_ at the end of a word, this will cause the emphasis to run all the way through to the end of the paragraph.
- **This is especially troublesome with subscript syntax within math expressions.

For example, $\LaTeX$ syntax uses a single underscore to render the immediately following character in subscript. Thus, `H_2O` will become $H_2$O, but the unpaired underscore will cause all following characters to become emphasized.
#### Titles
- In the CodeMirror submodule, in markdown.js, a space should be added (after the hashes) to the regex for matching of headers, like so: `atxHeaderRE = /^#+\s/`.
- Ibidem: the CM class should match the actual heading level, like so: `state.header = match[0].length <= 6 ? match[0].length-1 : 6;`.
#### Lists
- In the CodeMirror submodule, in markdown.js, we want to add support for lettered ordered lists, like so: `olRE = /^([0-9]+\.|[A-z]+\))\s+/`
#### Horizontal Rules
The use of dashes (-) and asterisks (*) at the beginning of a new line is ambiguous: do they denote (unordered, bulleted) list items, or a horizontal rule?

--- no horizontal rule, but a nested list item (three levels deep)
---

No (nested) list item, but a horizontal rule.
#### Inline HyperLinks
Clickable links are [unsupported yet](https://github.com/cben/mathdown/issues/9), e.g.:

- <http://http://mathdown.net/>
- [Mathdown](http://mathdown.net "Collaborative markdown + math").
#### Email addresses
- Too greedy match: this:is@not-an-e-mail. (And the fulls-top period at the end of the string doesn’t belong to it, either.)
- Colons folllowing two chars, then followed by at least three chars, except space, get tokenized: aa:a, aa:ab, aa:abc, aa:abcd — why?
#### Referenced hyperlinks
- Identifiers of [referenced links][id] are not recognized as such.
- Neither are title attributes within the reference text:
[id]: http://mathdown.net "The math editor for the Web"
#### Footnotes and Inline References
- Footnote markers are not tokenized. [^†]

[^†]: Only the first word of the actual footnote text is tokenized.[^*]
[^*]: The asterisk should be a lawful character for footnote markers; i.e. there should not be any parsing inside a footnote marker.

- Cfr https://github.com/cben/mathdown/issues/40
#### Images
- No support for inline real-time rendering of images yet.
- Image definitions are not recognized as such:
![logo](http://rhythmus.be/favicon.ico "Rhythmus Typography")
#### Inline Code and Code blocks
- Bakcticked inline code (`literals`) are fine, as long as you do not use `\escape` backslashes: the literal will run through beyond the closing backtick, unless it is `preceeded by a space.
- 
````
There should be no parsing *inside* code blocks, _no_ Markdown, but no $\LaTex$ MathJax, either. $$\backslashes$$  back lashes.
```
#### Math and Equations
- Two single consecutive dollar signs within text may unintendly call MathJax, wich can cost you between $10 USD and $20 USD.

- The same goes for double dollar signs: $$ no equation $$.

- All formulas must be written on one line; there’s no support for complex math, like matrices:

$$
\begin{matrix}\tau & = & \varphi(v)\beta(t-\frac{v}{V^{2}}x),\\
\\\xi & = & \varphi(v)\beta(x-vt),\\
\\\eta & = & \varphi(v)y,\\
\\\zeta & = & \varphi(v)z,\\
\end{matrix}
$$

- `\newcommand` mostly works but you may need to reload the page for the definition to take effect.
- Equations are numbered with a css hack: `\label` can’t be used; causes “multiply defined” error.
#### Tables
No support yet.
#### Raw html
No support yet.
