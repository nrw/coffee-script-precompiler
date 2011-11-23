var async, coffeescript, compileCoffee, logger, path, spawn, utils;
coffeescript = require("../coffee-script/lib/coffee-script/coffee-script");
async = require("async");
logger = require("kanso/logger");
utils = require("kanso/utils");
spawn = require("child_process").spawn;
path = require("path");
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
module.exports = function(root, path, settings, doc, callback) {
  var paths;
  if (!settings.coffeescript || !settings.coffeescript.compile) {
    return callback(null, doc);
  }
  paths = settings.coffeescript.compile || [];
  if (!Array.isArray(paths)) {
    paths = [paths];
  }
  return async.forEach(paths, (function(p, cb) {
    var filename, name;
    name = p.replace(/\.coffee$/, ".js");
    filename = utils.abspath(p, path);
    return compileCoffee(path, filename, settings, function(err, js) {
      if (err) {
        return cb(err);
      }
      doc._attachments[name] = {
        content_type: "text/javascript",
        data: new Buffer(js).toString("base64")
      };
      return cb();
    });
  }), function(err) {
    return callback(err, doc);
  });
};