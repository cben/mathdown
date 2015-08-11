Supported Markdown syntaxes:
# Headings start with # sign.
## 2nd-level heading
### 3rd-level heading etc...

----

Use asterisks for *emphasis* and ***strong* emphasis**.  _Underlines_ also work.

Surround literal text with (e.g. computer code) with `backticks`.
For a literal block:
```
surround with triple backticks
```
or:
    indent by 4 spaces.

# Lists
↓ You must leave an empty line before a list:

 1. First ordered list item
    Additional lines (like this one) in a list should be indented **4 space** more.
   (Tip: add spaces until the color changes.  See how this line is black?  That tells you it's not indented enough.)

 2. Another item

      * Unordered sub-list.  You can use `* `, `+ ` or `- ` bullets (note the space!).
        another line within the sublist item.
        ↑ indented 8 spaces.
        (Tip: press **Tab / Shift+Tab** to indent / dedent current line or selection.)

 3. And another item.

     1. Ordered sub-list.

# Quotes
Like in email, preceded by `>` character.
> ...
> I shall be telling this with a sigh
> Somewhere ages and ages hence:
> > Two roads diverged in a wood, and I—
> > I took the one less traveled by,
> > And that has made all the difference.

# Links
Simplest format: [Linked text](https://example.com).
You can also write more compactly [linked text][ex] and define where that leads separately:

[ex]: https://example.com

BUG: links are not clickable. [https://github.com/cben/mathdown/issues/9]
The only way to follow a link is to copy-paste it into the address bar...

# Math
Use $\LaTeX$ syntaxes: surround with dollars or backslash-parens for \(inline\) math and
double dollars or backslash-brackets for
$$display$$
math.
BUG: the whole formula must be written on one line

To **edit a formula** move the cursor into it using arrow keys.  It will re-render as soon as you move outside.
Try it now: $\sum a_i + \frac{1}{b_i}$ <- put cursor here and move left.

# Export to various formats
> The nice thing about standards is that you have so many to choose from.  -- Andrew Tanenbaum

Mathdown doesn't yet help you with this, but the syntax you're writing is standard Markdown.

1. Select all (Ctrl+A), copy-paste into a local file.  Save with .md extension.

2. The best conversion tool is [Pandoc](http://pandoc.org/).  You'll want to run something like:

      pandoc -s --mathjax -f markdown_github-blank_before_header+tex_math_dollar+tex_math_single_backslash MY_FILE.md -o MY_FILE.html

   The output format is inferred from the `-o` extension, can be overriden with e.g. `-t beamer`.
