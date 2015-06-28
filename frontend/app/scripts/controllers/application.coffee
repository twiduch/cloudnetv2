m = require 'mithril'
api = require 'lib/api'

class ApplicationController
  constructor: ->
    @api = api
    @currentUser = @api.currentUser


module.exports = ApplicationController
