// Main code running in every mathdown document (all shown via index.html).

"use strict";

// Logging
// =======

// Prevent errors on IE (but do strive to log somehow if IE Dev Tools are open).
function log() {
  try {
    if(console.log.apply) {
      console.log.apply(console, arguments);
    } else {
      /* IE's console.log doesn't have .apply, .call, or bind. */
      console.log(Array.prototype.slice.call(arguments));
    }
  } catch (err) {}
}

// Send MathJax messages to log.
log("MJ:", MathJax.Message.Log());
var origFilterText = MathJax.Message.filterText;
MathJax.Message.filterText = function(text, n, msgType) {
  // Exclude non-informative "Processing/Typesetting math: 0% / 100%".
  if(msgType !== "ProcessMath" && msgType !== "TypesetMath") {
    log("MJ:", text, "[" + msgType + "]");
  }
  return origFilterText(text, n, msgType);
}

var statusElement = document.getElementById("status");
// Show "flash" message.  To hide use className="" but it's still
// useful to provide text (briefly visible).
function setStatus(className, text) {
  statusElement.innerHTML = "";
  statusElement.className = className;
  if(text) {
    statusElement.appendChild(document.createTextNode(text));
  }
}

// Random pad IDs
// ==============

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
document.getElementById("new").onclick = newPad;

// Editor
// ======

// Apply class="leadingspace" to leading whitespace so we can make it monospace.
// Stolen from CodeMirror/addon/edit/trailingspace.js.
CodeMirror.defineOption("showLeadingSpace", false, function(cm, val, prev) {
  if (prev === CodeMirror.Init) prev = false;
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

// Defaults are insert \t / reindent.  Indent / dedent are more expected & useful.
CodeMirror.keyMap["default"]["Tab"] = "indentMore";
CodeMirror.keyMap["default"]["Shift-Tab"] = "indentLess";

function createEditor(docDirection) {
  return CodeMirror.fromTextArea(document.getElementById("code"),
                                 {foldGutter: true,
                                  gutters: ["CodeMirror-foldgutter"],
                                  indentUnit: 4,
                                  lineNumbers: false,
                                  lineWrapping: true,
                                  mode: "gfm_header_line_classes",
                                  showLeadingSpace: true,
                                  direction: docDirection});
}

function setupEditor(editor) {
  // Indent soft-wrapped lines.  Based on CodeMirror/demo/indentwrap.html.
  var leadingSpaceListBulletsQuotes = /^\s*([*+-]\s+|\d+\.\s+|>\s*)*/;
  editor.on("renderLine", function(cm, line, elt) {
    // Show continued list/qoute lines aligned to start of text rather
    // than first non-space char.  MINOR BUG: also does this inside
    // literal blocks.
    // Would like to measure real sizes of spans styled
    // /leadingspace|formatting-list|formatting-quote/, but can't do
    // that without inserting them into the DOM.  So count chars instead.
    var leading = (leadingSpaceListBulletsQuotes.exec(line.text) || [""])[0];
    var off = CodeMirror.countColumn(leading, leading.length, cm.getOption("tabSize"));
    // Using "ex" is a bit better than cm.defaultCharWidth() — it picks up
    // increased font if applied to whole line, i.e. in header lines
    // (not that it makes sense to indent headers).
    // However any resemblance of 1ex to the width of one monospace char
    // is purely coincidental (1em is way too wide in practice).
    elt.style.textIndent = "-" + off + "ex";

    // We need to know line direction to set paddingLeft or paddingRight appropriately.
    // TODO: CM should expose getDirection().
    var lineDirection = elt.style.direction || cm.getDoc().direction;
    // TODO: CM doesn't re-run this hook when line direction changed :-(
    // => KLUDGE: set both paddings!  In fact this is a good for mixed-direction docs anyway -
    //    long lines of opposite direction won't visually break indentation structrure.
    //    But I'm afraid it may be a nuisance on pure-LTR docs, so as a compromise
    //    I set only paddingLeft on LTR lines in LTR docs.
    if (docDirection === "rtl" || lineDirection === "rtl") {
      elt.style.paddingRight = off + "ex";
      elt.style.paddingLeft = off + "ex";
    } else {
      elt.style.paddingLeft = off + "ex";
    }
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
    if (changeObj.from.line === 0) {
      updateTitle();
    }
  });

  CodeMirror.hookMath(editor, MathJax);
}

// Firepad
// =======

function setupFirepad(editor, firepad) {
  firepad.on("ready", function() {
    setStatus("", "done");

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
}

function timestampMs() {
  return new Date().getTime();
}

  //  firepadRef.child("
function setupUnsavedWarning(connectedRef, editor, firepad, headless) {
  var loaded = false, connected = false, believedSynced = true, testedSynced = true;
  var testSyncIntervalMs = 1*1000;

  firepad.on("ready", function() {
    // before this we don't want to show messages, but we do run the
    // callbacks to end up with correct believedSynced etc.
    loaded = true;
    updateStatus();
  });
  connectedRef.on("value", function(snapshot) {
    connected = snapshot.val();
    updateStatus();
  });
  firepad.on("synced", function(isSynced) {
    believedSynced = isSynced;
    updateStatus();
  });
  setInterval(function () {
    if(connected) {             // meaningless if offline
      headless.getText(function(fetchedText) {
        var editorText = editor.getValue();
        // This is not reliable during typing (by the time we
        // reconstruct from firebase editor text might have changed),
        // as well as during *incoming* changes from other editor.
        testedSynced = (fetchedText === editorText);
        updateStatus();
      });
    }
  }, testSyncIntervalMs);

  function updateStatus() {
    log("loaded = ", loaded, "connected =", connected,
        "believedSynced = ", believedSynced, "testedSynced =", testedSynced);
    if(!loaded) {
      return;  // don't disturb "loading..." message (there can be no unsaved state yet).  TODO: OFFLINE TYPING?
    }
    if(connected) {
      if(believedSynced) {
        if(testedSynced) {
          setStatus("", "saved");
        } else {
          setStatus("warning", "Online but unsaved — BUG?");
        }
      } else {
        setStatus("info", "Unsaved!");
      }
    } else {  // not connected.
      if(believedSynced) {
        setStatus("info", "Offline");
      } else {
        setStatus("warning", "Offline — Unsaved changes!");
      }
    }
  }
}

// URL parameters => load document
// ===============================

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

var queryParams = locationQueryParams();
var doc = queryParams["doc"];
// EXPERIMENTAL KLUDGE param: for now we support dir=rtl to make RTL docs (somewhat) practical
// (but don't expose it in the GUI).
// In the future it might be ignored - once we autodetect each line's base direction (#23).
// Also, document direction is semantic, it makes more sense to store it in firebase?
var docDirection = (queryParams["dir"] === "rtl" ? "rtl" : "ltr");

if(doc === undefined) {
    // TODO: this should be a server-side redirect (when we have a server).
    window.location.search = "?doc=about";
} else {
  var rootRef = new Firebase("https://mathdown.firebaseIO.com/");
  var firepadRef = rootRef.child("firepads").child(doc);
  log("firebase ref:", firepadRef.toString());

  var editor = createEditor(docDirection);
  setupEditor(editor);

  var firepad = Firepad.fromCodeMirror(firepadRef, editor);
  setupFirepad(editor, firepad);

  var connectedRef = rootRef.child(".info/connected");
  var headless = new Firepad.Headless(firepadRef);
  setupUnsavedWarning(connectedRef, editor, firepad, headless);
}
