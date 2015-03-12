m = require 'mithril'

module.exports = (controller) ->
  m 'header', [
    m 'h1', 'Cloud.net'
    m '.flash_message', window.flashMessage()
  ]
