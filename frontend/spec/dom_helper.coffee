require 'spec_helper'
uri = require 'url'

# A JS DOM!
jsdom = require('jsdom')
mochaJsdom = require('mocha-jsdom')
m = {}

# Register before-suite and after-suite hooks to setup/teardown the jsdom window object.
# Note that the global window object won't exist until the suite's before() hook has run.
mochaJsdom({
  # Send all browser-based errors to the node console
  virtualConsole: jsdom.createVirtualConsole().sendTo(console)
})

before ->
  # scrollTo isn't implemented by jsdom for some reason?
  window.scrollTo = ->
    true
  global.$ = require('jquery')
  # NB: mithril *must* be required *after* jsdom initialisation (which happens in before())
  m = require 'mithril'

  # HACK for jsdom's lack of insertAdjacentHTML. Watch https://github.com/tmpvar/jsdom/issues/1219
  window.HTMLElement.prototype.insertAdjacentHTML = (thing, data) ->
    # noop for now
    return true


beforeEach ->
  global.localStorage = {}

  # Manually manipulatable AJAX responses
  global.xhrRequests = []
  xhr = sinon.useFakeXMLHttpRequest()
  xhr.onCreate = (request) ->
    xhrRequests.push request

  # Because mithril calls window.XMLHttpRequest rather than the naked global faked by sinon
  window.XMLHttpRequest = XMLHttpRequest


module.exports = {
  load: (path, callback) ->
    # The actual call to load up cloud.net
    if $('header').length
      m.route(path)
    else
      global.windowPath = path
      require 'main'
      m.redraw(true)
    callback()

  # Given the path for an AJAX request, provide a known fake response
  xhrResponseFor: (path, response = {}) ->
    matchedRequest = xhrRequests.find (request) ->
      return unless request.url
      url = uri.parse request.url
      url.path == path

    throw new Error "No pending AJAX request matching the path: #{path}" unless matchedRequest
    status = response.status || 200
    headers = response.headers || {}
    body = JSON.stringify(response.json) || '[{}]'
    matchedRequest.respond status, headers, body

    # Force an immediate mithril redraw
    m.redraw(true)

    matchedRequest
}
