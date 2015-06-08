m = require 'mithril'
api = require 'lib/api'

class Datacentres
  @all: ->
    api.get 'datacentres'


module.exports = Datacentres
