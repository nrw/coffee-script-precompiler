coffeescript = require("../coffee-script/lib/coffee-script/coffee-script")
async = require("async")
logger = require("kanso/logger")
utils = require("kanso/utils")
spawn = require("child_process").spawn
path = require("path")
modules = require('kanso/modules')

compileCoffee = (project_path, filename, settings, callback) ->
  logger.info "compiling", utils.relpath(filename, project_path)
  args = [ filename ]
  args.unshift "--print" #  if settings.less.compress
  coffeec = spawn(__dirname + "/../coffee-script/bin/coffee", args)
  js = ""
  err_out = ""
  coffeec.stdout.on "data", (data) ->
    js += data

  coffeec.stderr.on "data", (data) ->
    err_out += data

  coffeec.on "exit", (code) ->
    if code is 0
      callback null, js
    else
      callback new Error(err_out)

# root {Boolean} whether the package is the main (top) package being built
# (always true for postprocessors)
# path {String} the fs path of the package directory
# settings {Object} the values in kanso.json
# doc {Object} the design doc being built
# callback {Function} function to call after the processor is complete or on error
# the first argument of the callback is an optionall error
# the second is the udpated doc object

###
  DOCSTRING FOR modules.add
  
  Add the module source to the document in the correct location for requiring
  server-side, then add the path to the _modules property for use by the
  modules plugin postprocessor (when creating the kanso.js attachment)
  
  Returns the updated document.
  
  @param {Object} doc
  @param {String} path
  @param {String} src
  @returns {Object}
###


module.exports = (root, path, settings, doc, callback) ->
  return callback(null, doc)  if not settings.coffeescript or not settings.coffeescript.compile
  paths = settings.coffeescript.compile or []
  paths = [ paths ]  unless Array.isArray(paths)
  async.forEach paths, ((p, cb) ->
    name = p.replace(/\.coffee$/, ".js")
    filename = utils.abspath(p, path)
    compileCoffee path, filename, settings, (err, js) ->
      return cb(err)  if err
      modules.add(doc, filename, new Buffer(js).toString("base64"))
      cb()
  ), (err) ->
    callback err, doc


