var URL, coffee, fs, http, processData, qs, sys, util;
sys = require('sys');
fs = require('fs');
URL = require('url');
http = require('http');
qs = require('querystring');
util = require('util');
coffee = require('coffee-script');
processData = function(data, method, response) {
  var f, fl, list, out, params, stats, _i, _len;
  console.log("dataDir:");
  params = qs.parse(data);
  console.dir(params);
  try {
    console.log("processing request for " + params.action);
    switch (params.action) {
      case null:
        out = "specify the action yo";
        break;
      case 'compile':
        out = coffee.compile(params.content);
        break;
      case 'fileList':
        list = {};
        fl = fs.readdirSync('.');
        for (_i = 0, _len = fl.length; _i < _len; _i++) {
          f = fl[_i];
          stats = fs.statSync(f);
          list[f] = stats.isDirectory() ? 'directory' : 'file';
        }
        out = JSON.stringify(list);
        break;
      case 'log':
        console.log("LOG:" + params.message);
        out = "";
    }
  } catch (e) {
    console.log(e.stack);
    out = e.message;
  }
  return response.end(out);
};
http.createServer(function(req, res) {
  var data, method, url;
  try {
    url = URL.parse("." + req.url).pathname;
    console.log("url: " + url);
    method = req.method;
    console.log("method:" + method);
    data = null;
    req.addListener('data', function(d) {
      return data = d.toString();
    });
    return req.addListener('end', function() {
      var stats;
      if ((data != null) && method !== "GET") {
        console.log("data:" + data);
        res.writeHead(200, {
          'Content-Type': 'application/json'
        });
        return processData(data, method, res);
      } else {
        try {
          res.writeHead(200, {
            'Content-Type': 'text/html'
          });
          stats = fs.statSync(url);
          if (stats.isDirectory()) {
            url = url + '/index.html';
            url = url.replace('//', '/');
            return res.end(fs.readFileSync(url));
          } else {
            return res.end(fs.readFileSync(url));
          }
        } catch (e) {
          console.error(e.message);
          return res.end(e.message);
        }
      }
    });
  } catch (e) {
    console.error(e.message);
    return res.end(e.message);
  }
}).listen(8000);