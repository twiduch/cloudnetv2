m = require 'mithril'
ApplicationController = require 'controllers/application'
Datacentres = require 'models/datacentres'

class HomeController extends ApplicationController
  constructor: ->
    super
    @apiStatus = @api.get('/')


module.exports = HomeController
