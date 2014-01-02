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

var editor = CodeMirror.fromTextArea(document.getElementById("code"),
                                     {indentUnit: 4,
                                      lineNumbers: false,
                                      lineWrapping: true,
                                      mode: {name: "gfm"}});

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
        // HACK: Pad the editor with a few emty lines so it looks
        // more inviting to write in.
        "\n" +
        "\n"
    );
  }

  // CM's autofocus option doesn't work with Firepad - seems focused
  // but can't type.  Focusing here after Firepad init works.
  editor.focus();

  // Queuing this allows text to appear before math.
  // TODO: Race condition with early typing?
  MathJax.Hub.Queue(function() {
    CodeMirror.renderMath(editor, MathJax);
  });
});
