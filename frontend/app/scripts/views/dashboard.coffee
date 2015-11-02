m = require 'mithril'

servers = (controller) ->
  m 'ul',
    controller.servers().map (server) ->
      m 'li',
        m 'strong', server.name
        m 'ul',
          m 'li', "CPU: #{server.cpus}"
          m 'li', "RAM: #{server.memory}GB"
          m 'li', "Disk: #{server.disk_size}GB"
          m 'li', "OS: #{server.template.label}"
          m 'li', "State: #{server.state}"
          m 'li', "IP: #{server.ip_address}"

module.exports = (controller) ->
  user = controller.currentUser()
  created_at = new Date(user.created_at)
  [
    m 'h1', 'Dashboard'
    m 'h2', user.full_name
    m 'ul',
      m 'li', "Registered: #{created_at.toDateString()}"
      m 'li', "API Key: #{user.cloudnet_api_key}"
      m 'li', "Status: #{user.status}"
    m 'h2', 'Servers'
      if controller.servers()
        servers(controller)
      else
        m 'em', "You don't have any servers"
  ]
