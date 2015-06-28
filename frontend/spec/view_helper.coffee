require 'spec_helper'

m = require 'mithril'
mq = require 'mithril-query'
dom = mq document.body

# Only require 'main.coffee' when needed, because requiring makes it render the home page
# unless told otherwise by `window.location`
dom.gotoPath = (path) ->
  window.location.pathname = path
  require 'main'
  m.route(path)
  @frameResolve()

dom.frameResolve = ->
  window.requestAnimationFrame.$resolve()

beforeEach ->
  dom = mq document.body

module.exports = dom
