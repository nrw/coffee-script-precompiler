# Show functions to be exported from the design doc.

templates = require 'duality/templates'


exports.welcome = (doc, req) ->
    title: 'It worked!',
    content: templates.render('welcome.html', req, {})

exports.not_found = (doc, req) ->
    title: '404 - Not Found',
    content: templates.render('404.html', req, {})
