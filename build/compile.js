var async, coffeescript, compileCoffee, logger, modules, path, spawn, utils;
coffeescript = require("../coffee-script/lib/coffee-script/coffee-script");
async = require("async");
logger = require("kanso/logger");
utils = require("kanso/utils");
spawn = require("child_process").spawn;
path = require("path");
modules = require('kanso/modules');
compileCoffee = function(project_path, filename, settings, callback) {
  var args, coffeec, err_out, js;
  logger.info("compiling", utils.relpath(filename, project_path));
  args = [filename];
  args.unshift("--print");
  coffeec = spawn(__dirname + "/../coffee-script/bin/coffee", args);
  js = "";
  err_out = "";
  coffeec.stdout.on("data", function(data) {
    return js += data;
  });
  coffeec.stderr.on("data", function(data) {
    return err_out += data;
  });
  return coffeec.on("exit", function(code) {
    if (code === 0) {
      return callback(null, js);
    } else {
      return callback(new Error(err_out));
    }
  });
};
module.exports = {
  before: 'properties',
  run: function(root, path, settings, doc, callback) {
    var paths;
    if (!settings["coffee-script"]) {
      return callback(null, doc);
    }
    if (!settings["coffee-script"]["modules"] && !settings["coffee-script"]["attachments"]) {
      return callback(null, doc);
    }
    paths = settings["coffee-script"]["modules"] || [];
    if (!Array.isArray(paths)) {
      paths = [paths];
    }
    return async.forEach(paths, (function(p, cb) {
      var pattern;
      pattern = /.*\.coffee/i;
      return utils.find(p, pattern, function(err, data) {
        var file, filename, name, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          file = data[_i];
          name = file.replace(/\.coffee$/, "");
          filename = utils.abspath(name, path);
          _results.push(compileCoffee(path, filename, settings, function(err, js) {
            if (err) {
              return cb(err);
            }
            modules.add(doc, name, js.toString());
            return cb();
          }));
        }
        return _results;
      });
    }), function(err) {
      return callback(err, doc);
    });
  }
};