m = require 'mithril'

module.exports = (controller) ->
  [
    m 'h1', 'Dashboard'
    m 'ul', m 'li', "#{key}: #{value}" for key, value of controller.currentUser()
  ]
