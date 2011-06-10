var CoffeeMode, JavaScriptMode, body, compile, compileKeyBind, debug, debugDiv, editor, input, output, sendReq, serverLog, showSaveWindow, specialKeyBind, timer, trim;
input = $('#input');
body = $('body');
debugDiv = $('#debug');
editor = ace.edit("input");
output = ace.edit("output");
timer = null;
trim = function(str) {
  return str.replace(/(^\s+|\s+$)/, '');
};
compile = function() {
  var compiled, msg;
  try {
    compiled = CoffeeScript.compile(editor.getSession().getValue(), {
      bare: true
    });
    return output.getSession().setValue(compiled);
  } catch (error) {
    msg = error.message;
    return output.getSession().setValue(msg);
  }
};
sendReq = function(data, method, callback) {
  return $.ajax({
    type: "POST",
    url: "http://localhost:8000/",
    data: data,
    timeout: 3000,
    success: function(data, text) {
      debug("" + (data.toString()) + ":" + text);
      return callback(data);
    },
    error: function(data) {
      return debug("REQUEST ERROR:" + data.message);
    }
  });
};
serverLog = function(msg) {
  return sendReq({
    action: 'log',
    message: msg
  }, "POST", function() {});
};
debug = function(msg) {
  debugDiv.html("" + (debugDiv.html()) + "\n" + msg);
  serverLog(msg);
  return debugDiv.scrollTop(debugDiv[0].scrollHeight);
};
compileKeyBind = function(e) {
  if (!e.metaKey) {
    if (timer != null) {
      clearTimeout(timer);
    }
    return timer = setTimeout((function() {
      return compile();
    }), 500);
  }
};
showSaveWindow = function(path) {
  debug('show save window');
  return sendReq({
    action: 'fileList',
    path: path
  }, 'POST', function(data) {
    return debug("file list:" + (data.toString()));
  });
};
specialKeyBind = function(e) {
  var code;
  if (e.metaKey) {
    code = e.keyCode ? e.keyCode : e.which;
    switch (code) {
      case 82:
        return;
      case 114:
        return;
      case 83:
        showSaveWindow('.');
    }
    e.preventDefault();
    e.stopPropagation();
    return debug(code);
  }
};
input.bind('keypress keydown', compileKeyBind);
body.bind('keypress keydown', specialKeyBind);
CoffeeMode = require("ace/mode/coffee").Mode;
editor.getSession().setMode(new CoffeeMode());
JavaScriptMode = require("ace/mode/javascript").Mode;
output.getSession().setMode(new JavaScriptMode());
output.setReadOnly(true);
editor.focus();
if (editor.getSession().getValue() != null) {
  compile();
}
Run