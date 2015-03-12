m = require 'mithril'

module.exports = (controller) ->
  controller.datacentres().map (datacentre) ->
    console.log datacentre
    [
      m 'h1', "#{datacentre.label} (#{datacentre.coords})"
      m 'ul', datacentre.templates.map (template) ->
        m 'li', template.label
    ]
