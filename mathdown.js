// Main code running in every mathdown document (all shown via index.html).

"use strict";

// Prevent errors on IE.  Might not actually log.
function log() {
  try { console.log.apply(console, arguments); } catch (err) {}
}

// Send MathJax messages to log.
log("MJ:", MathJax.Message.Log());
var origFilterText = MathJax.Message.filterText;
MathJax.Message.filterText = function(text, n, msgType) {
  // Exclude non-informative "Processing/Typesetting math: 0% / 100%".
  if(msgType != "ProcessMath" && msgType != "TypesetMath") {
    log("MJ:", text, "[" + msgType + "]");
  }
  return origFilterText(text, n, msgType);
}

function locationQueryParams() {
  /* If more is needed, use https://github.com/medialize/URI.js */
  var queryParts = window.location.search.replace(/^\?/g, "").split("&");
  var params = {};
  for(var i = 0; i < queryParts.length; i++) {
    var keyval = queryParts[i].split("=");
    params[decodeURIComponent(keyval[0])] = decodeURIComponent(keyval[1] || "");
  }
  return params;
}

// Return an int in [0, 62).
var random62 = (window.crypto && window.crypto.getRandomValues) ?
    function() {
      var buf = new Uint8Array(1);
      var n;
      do {
        window.crypto.getRandomValues(buf);
        n = (buf[0] % 64);
      } while(n >= 62);
      return n;
    }
    :
    function() {
      // Math.random is pathetic on most browsers, though some initialize
      // with secure seed: http://stackoverflow.com/a/18507748/239657
      return Math.floor(Math.random() * 62);
    };

function randomBase62(length) {
  var base62 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  var text = "";
  for(var i=0; i < length; i++)
    text += base62.charAt(random62());
  return text;
}

function newPad() {
  var doc = randomBase62(11);  // 62**11 ~= 2**65.
  window.open("?doc=" + doc, "_blank");
}

var doc = locationQueryParams()["doc"];
if(!doc) {
  window.location.search = "?doc=about";
}
var firepadsRef = new Firebase("https://mathdown.firebaseIO.com/firepads");
var firepadRef = firepadsRef.child(doc);
log("firebase ref:", firepadRef.toString());

// Stolen from CodeMirror/addon/edit/trailingspace.js.
CodeMirror.defineOption("showLeadingSpace", false, function(cm, val, prev) {
  if (prev == CodeMirror.Init) prev = false;
  if (prev && !val)
    cm.removeOverlay("leadingspace");
  else if (!prev && val)
    cm.addOverlay({
      token: function(stream) {
        if (stream.sol() && stream.eatSpace()) {
          return "leadingspace";
        } else {
          stream.skipToEnd();
          return null;
        }
      },
      name: "leadingspace"
    });
});

// To add vertical margin to headers, the .cm-header[N] classes must apply to
// <pre> and not the <span>.  Wrap the mode to achieve this.
CodeMirror.defineMode("gfm_header_line_classes", function(cmConfig, modeCfg) {
  modeCfg.name = "gfm";
  modeCfg.highlightFormatting = true;
  var mode = CodeMirror.getMode(cmConfig, modeCfg);
  var origToken = mode.token;
  // We use GFM mostly for URLs but don't want GitHub-specific formatting that
  // makes `0123456789` a link.  TODO: add mode option of gfm.js.
  var shaOrIssueRE = /^(?:[a-zA-Z0-9\-_]+\/)?(?:[a-zA-Z0-9\-_]+@)?(?:[a-f0-9]{7,40})|b^(?:[a-zA-Z0-9\-_]+\/)?(?:[a-zA-Z0-9\-_]+)?#[0-9]+$/;
  mode.token = function(stream, state) {
    var classes = origToken(stream, state) || "";
    if (shaOrIssueRE.test(stream.current())) {
      classes = classes.replace(/(^| )link( |$)/, " ");
    }
    classes = classes.replace(/(^| )(header\S*)/g, "$1line-cm-$2");
    return /^\s*$/.test(classes) ? null : classes;
  }
  return mode;
});

var editor = CodeMirror.fromTextArea(document.getElementById("code"),
                                     {indentUnit: 4,
                                      lineNumbers: false,
                                      lineWrapping: true,
                                      mode: "gfm_header_line_classes",
                                      showLeadingSpace: true});

// Indent soft-wrapped lines.  Based on CodeMirror/demo/indentwrap.html.
var leadingSpaceAndListBullets = /^\s*([*+-]\s+|\d+\.\s+)?/;
editor.on("renderLine", function(cm, line, elt) {
  // Would like to measure real sizes of /leadingspace|formatting-list/ styled
  // spans, but can't do that without inserting them into the DOM.
  var leading = (leadingSpaceAndListBullets.exec(line.text) || [""])[0];
  var off = CodeMirror.countColumn(leading, leading.length, cm.getOption("tabSize"));
  // Using "ex" is a bit better than cm.defaultCharWidth() — it picks up
  // increased font if applied to whole line, i.e. in header lines
  // (not that it makes sense to indent headers).
  elt.style.textIndent = "-" + off + "ex";
  elt.style.paddingLeft = off + "ex";
});
editor.refresh();

// Keep title and url #hash part in sync with first line of document.
function updateTitle() {
  var text = editor.getLine(0); // TODO: find first # Title line?
  text = text.replace(/^\s*#+\s*/, "");
  document.title = text + " | mathdown";
  window.location.hash = text.replace(/\W+/g, "-").replace(/^-/, "").replace(/-$/, "");
}
CodeMirror.on(editor.getDoc(), "change", function(doc, changeObj) {
  if (changeObj.from.line == 0) {
    updateTitle();
  }
});

CodeMirror.hookMath(editor, MathJax);

var firepad =  Firepad.fromCodeMirror(firepadRef, editor);
firepad.on("ready", function() {
  if (firepad.isHistoryEmpty()) {
    firepad.setText(
      "# Untitled\n" +
        "Bookmark this page — the random-looking address is the only way to access this document!\n" +
        "Share the link to collaborate.\n" +
        "Edits are saved in real time.\n" +
        "\n" +
        "Use Markdown for document structure and $\\LaTeX$ math syntax (see **Help** link above).\n" +
        "To edit formulas just enter them with arrow keys.\n" +
        // HACK: Pad the editor with a few empty lines so it looks
        // more inviting to write in.
        "\n" +
        "\n"
    );
  } else {
    // Keeping cursor at start (hopefully) reduces CM redrawing as
    // syntax highlight and math rendering changes line heights.
    editor.setCursor({line: 0, ch: 0});
  }

  // CM's autofocus option doesn't work with Firepad - seems focused
  // but can't type.  Focusing here after Firepad init works.
  editor.focus();

  // Queuing this allows text to appear before math.
  MathJax.Hub.Queue(function() {
    editor.renderAllMath();
  });
});
