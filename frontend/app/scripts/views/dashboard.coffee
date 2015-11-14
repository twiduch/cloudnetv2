m = require 'mithril'
keyValueWidget = require 'views/_partials/key_value_widget'

servers = (controller) ->
  m 'table',
    m 'thead',
      m 'tr',
        m 'th', 'Name'
        m 'th', 'State'
        m 'th', 'IP Address'
        m 'th', 'Operating System'
        m 'th', 'RAM (MBs)'
        m 'th', 'CPUs'
        m 'th', 'Disk Size (GBs)'
    m 'tbody'
      controller.servers().map (server) ->
        m 'tr',
          m 'td',
            m 'a', { href: "/servers/#{server.id}", config: m.route }, server.name
          m 'td', server.state
          m 'td', server.ip_address
          m 'td', server.template.label
          m 'td', server.memory
          m 'td', server.cpus
          m 'td', server.disk_size

module.exports = (controller) ->
  user = controller.currentUser()
  created_at = new Date(user.created_at)
  [
    m 'h1', 'Your Dashboard'
    m '.account-details',
      keyValueWidget {
        'Status': user.status,
        'API Key': user.cloudnet_api_key
      }
    m 'h2', 'Servers'
      if controller.servers()
        servers(controller)
      else
        m 'em', "You don't have any servers"
  ]
