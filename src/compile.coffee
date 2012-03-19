module.exports =
  before: "modules"
  run: (root, path, settings, doc, callback) ->
    modulesPaths = settings["coffee-script"]?["modules"]
    attachmentsPaths = settings["coffee-script"]?["attachments"]

    # Check that the settings are valid
    unless modulesPaths? or attachmentsPaths?
      console.log "CoffeeScript precompiler requires either a 'modules' or an 'attachment' setting"
      return callback(null, doc)

    modulesPaths ?= []
    attachmentsPaths ?= []

    # Grab required libraries
    async = require("async")
    utils = require("kanso-utils/utils")
    precompiler = require("kanso-precompiler-base")
    coffee = require("coffee-script")

    # Specify the regular expression patterns that identify coffee files 
    file_pattern = /.*\.coffee$/i
    extension_pattern = /\.coffee$/ 

    # Compile a CoffeeScript file and attach it to the design document
    compileAttachment = (filename, callback) ->
      rel = utils.relpath(filename, path)
      console.log("Compiling attachment #{rel}")

      js = coffee.compile fs.readFileSync(filename, 'utf8'), filename: rel
      name = rel.replace(extension_pattern, ".js")
      precompiler.addAttachment(doc, name, filename,js)
      callback(null, doc)

    # Compile a CoffeeScript file and add it as a CommonJS module to the design document
    compileModule = (filename, callback) ->
      rel = utils.relpath(filename, path)
      console.log("Compiling module #{rel}")

      js = coffee.compile fs.readFileSync(filename, 'utf8'), filename: rel
      name = rel.replace(extension_pattern, "")
      precompiler.addModule(doc, name, filename, js)
      callback(null, doc)

    # Extract the module and attachment paths from the settings
    modules = precompiler.normalizePaths(settings["coffee-script"]["modules"], path)
    attachments = precompiler.normalizePaths(attachmentsPaths, path)

    # Create continuations for the functions that process whole folders of modules and attachments
    processModules = async.apply(precompiler.processPaths, modules, file_pattern, compileModule)
    processAttachments = async.apply(precompiler.processPaths, attachments, file_pattern, compileAttachment)

    # Run the modules and attachments in parallel then callback to Kanso to tell it we are done, passing the design document
    async.parallel [processModules, processAttachments], (err, results)->
      callback(err, doc)

