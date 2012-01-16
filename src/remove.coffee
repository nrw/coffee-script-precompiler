module.exports =
  after: "attachments"
  run: (root, path, settings, doc, callback) ->
    for k of (doc._attachments or {})
      delete doc._attachments[k]  if /\.coffee$/.test(k)
    callback null, doc