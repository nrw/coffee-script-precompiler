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
/*
  DOCSTRING FOR modules.add
  
  Add the module source to the document in the correct location for requiring
  server-side, then add the path to the _modules property for use by the
  modules plugin postprocessor (when creating the kanso.js attachment)
  
  Returns the updated document.
  
  @param {Object} doc
  @param {String} path
  @param {String} src
  @returns {Object}
*/
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
      modules.add(doc, filename, new Buffer(js).toString("base64"));
      return cb();
    });
  }), function(err) {
    return callback(err, doc);
  });
};