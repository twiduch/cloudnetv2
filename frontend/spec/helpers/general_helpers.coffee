# Turn the logger off in test envs
Logger = require 'lib/logger'
Logger.level = Logger.OFF

global.env = 'TEST'

# Collection of general helpers
class SpecHelpers
  # Return a fake AJAX response. Must be called *after* any m.request calls
  @ajaxResponse: (response) ->
    _ajaxStub(response)

  # Return the request as the response
  @ajaxReturnRequestAsResponse: ->
    _ajaxStub(false)

  # Stub an AJAX response. Mithril's default AJAX stub actually fills the response with the
  # request details, which is handy for checking the HTTP methid etc. So to receive the request in
  # the response, just pass `false as an argument`
  _ajaxStub = (response) ->
    xhr = mock.XMLHttpRequest.$instances.pop()
    # Without defining responseText here, Mithril fills the response with the request instead
    xhr.responseText = JSON.stringify response unless response == false
    xhr.onreadystatechange()

module.exports = {
  localStorage: {},
  SpecHelpers: SpecHelpers
}
