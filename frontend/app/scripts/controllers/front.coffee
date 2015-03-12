m = require 'mithril'
ApplicationController = require 'controllers/application'
Datacentres = require 'models/datacentres'

class FrontController extends ApplicationController
  @view = 'front'
  constructor: ->
    super
    @datacentres = Datacentres.all()

module.exports = FrontController
