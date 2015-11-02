m = require 'mithril'
api = require 'lib/api'

class Servers
  @all: ->
    api.get('/servers').then(
      (response) ->
        mappable = typeof response.map == 'function'
        if mappable then response else []
    )


module.exports = Servers
