m = require 'mithril'
api = require 'lib/api'

class ApplicationController
  constructor: ->
    @api = api
    # unless api.loggedIn
    #   m.route '/login'
    # @action()


module.exports = ApplicationController
