m = require 'mithril'
keyValueWidget = require 'views/_partials/key_value_widget'
helpers = require 'lib/helpers'

module.exports = (controller) ->
  server = controller.server()
  usages = controller.usages()
  return unless server
  [
    m 'h1', server.name
    m '.server-details',
      keyValueWidget {
        'State': server.state,
        'Created': helpers.formatTime(server.created_at),
        'Last Change': helpers.formatTime(server.updated_at),
        'OS': server.template.label,
        'RAM': "#{server.memory}MB",
        'CPUs': server.cpus,
        'Disk': "#{server.disk_size}GB",
        'IP Address': server.ip_address,
        'Root Password': server.root_password
      }

    m 'h2', 'Usage'
    m '.server-usage',
      keyValueWidget {
        'Disk': "Read: #{usages.disk_read}k, Write: #{usages.disk_write}k"
        'Network': "Read: #{usages.network_read}k, Write: #{usages.network_write}k"
      }

    m 'h2', 'Activity'
    m '.server-activity',
      server.transactions.reverse().map (transaction) ->
        return if transaction.details.length > 50
        detail = transaction.details.replace(/_/g, ' ')
        m 'div', "#{helpers.formatTime(transaction.date)}: ",
          m 'strong', detail
  ]
