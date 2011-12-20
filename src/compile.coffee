async = require("async")
logger = require("kanso/logger")
utils = require("kanso/utils")
spawn = require("child_process").spawn
path = require("path")
modules = require("kanso/modules")

module.exports =
  before: "properties"
  run: (root, path, settings, doc, callback) ->
    return callback(null, doc)  unless settings["coffee-script"]
    return callback(null, doc)  if not settings["coffee-script"]["modules"] and not settings["coffee-script"]["attachments"]

    module_paths = settings["coffee-script"]["modules"] or []
    module_paths = [ module_paths ]  unless Array.isArray(module_paths)
    
    attach_paths = settings["coffee-script"]["attachments"] or []
    attach_paths = [ attach_paths ] unless Array.isArray(attach_paths)
    
    apply_compile_modules = async.apply(compile_modules, doc, path)
    apply_compile_attachments = async.apply(compile_attachments, doc, path)

    async.parallel [
      async.apply(async.forEach, module_paths, apply_compile_modules),
      async.apply(async.forEach, attach_paths, apply_compile_attachments)
    ], (err) -> callback err, doc

compile_modules = (doc, path, paths, callback) ->
  pattern = /.*\.coffee$/i
  utils.find utils.abspath(paths, path), pattern, (err, data) ->
    return callback(err)  if err 
    apply_compile_module = async.apply(compile_module, doc, path)
    async.forEach data, apply_compile_module, callback

compile_module = (doc, path, filename, callback) ->
  name = utils.relpath(filename, path).replace(/\.coffee$/, "")
  compile_coffee path, filename, (err, js) ->
    return callback(err)  if err
    modules.add doc, name, js.toString()
    callback()

compile_attachments = (doc, path, paths, callback) ->
  pattern = /.*\.coffee$/i
  utils.find utils.abspath(paths, path), pattern, (err, data) ->
    return callback(err)  if err
    apply_compile_attachment = async.apply(compile_attachment, doc, path)
    async.forEach data, apply_compile_attachment, callback

compile_attachment = (doc, path, filename, callback) ->
  name = utils.relpath(filename, path).replace(/\.coffee$/, ".js")
  compile_coffee path, filename, (err, js) ->
    return callback(err)  if err
    doc._attachments[name] = 
      content_type: "application/javascript"
      data: new Buffer(js).toString("base64")
    callback()

compile_coffee = (project_path, filename, callback) ->
  logger.info "compiling", utils.relpath(filename, project_path)

  args = [ filename ]
  args.unshift "--print"
  coffeec = spawn(__dirname + "/../../coffee-script/coffee-script/bin/coffee", args)
  
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
