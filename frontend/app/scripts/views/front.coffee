m = require 'mithril'

module.exports = (controller) ->
  [
    m 'h1', 'Currently Available Providers'
    controller.datacentres().map (datacentre) ->
      [
        m 'strong', "#{datacentre.label}"
        m 'ul',
          m 'li', "Coordinates: #{datacentre.coords}"
          m 'li', "#{datacentre.templates.length} templates"
      ]
  ]
