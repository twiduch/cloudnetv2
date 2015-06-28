m = require 'mithril'
api = require 'lib/api'

class Datacentres
  @all: ->
    api.get('/datacentres').then(
      (response) ->
        mappable = typeof response.map == 'function'
        if mappable then response else []
    )


module.exports = Datacentres
