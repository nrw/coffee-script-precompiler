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
  args.unshift "--print"
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

module.exports =
  before: 'properties'
  run: (root, path, settings, doc, callback) ->
    return callback(null, doc) if not settings["coffee-script"]
    return callback(null, doc) if not settings["coffee-script"]["modules"] and not settings["coffee-script"]["attachments"]
    paths = settings["coffee-script"]["modules"] or []
    paths = [ paths ]  unless Array.isArray(paths)
    async.forEach paths, ((p, cb) ->
      name = p.replace(/\.coffee$/, "")
      filename = utils.abspath(p, path)
      compileCoffee path, filename, settings, (err, js) ->
        return cb(err)  if err
        modules.add(doc, name, js.toString())
        cb()
    ), (err) ->
      callback err, doc


