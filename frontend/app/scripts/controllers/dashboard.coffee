m = require 'mithril'
ApplicationController = require 'controllers/application'
Servers = require 'models/servers'

class DashboardController extends ApplicationController
  constructor: ->
    super
    @servers = Servers.all()

module.exports = DashboardController
