m = require 'mithril'
api = require 'lib/api'

class Servers
  @all: ->
    api.get('/servers').then(
      (response) ->
        mappable = typeof response.map == 'function'
        if mappable then response else []
    )

  @get: (id) ->
    api.get("/servers/#{id}")


module.exports = Servers
