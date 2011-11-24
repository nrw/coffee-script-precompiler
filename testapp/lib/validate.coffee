# The validate_doc_update function to be exported from the design doc.

types = require 'couchtypes/types'
app_types = require './types'


module.exports = (newDoc, oldDoc, userCtx) ->
    types.validate_doc_update app_types, newDoc, oldDoc, userCtx
