m = require 'mithril'
api = require 'api'

class Datacentres
  @all: ->
    api.req '/datacentres'


module.exports = Datacentres
