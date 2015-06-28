m = require 'mithril'

module.exports = (controller) ->
  console.log controller.currentUser()
  [
    m 'h1', "Dashboard"
    m 'ul', m 'li', "#{key}: #{value}" for key, value of controller.currentUser()
  ]
