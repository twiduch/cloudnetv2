m = require 'mithril'

module.exports = (content) ->
  (controller) ->
    [
      m 'header', [
        m 'h1', 'Cloud.net'
        m 'p', controller.api.message()
      ]
      content(controller)
      m 'footer', '© 2015'
    ]
