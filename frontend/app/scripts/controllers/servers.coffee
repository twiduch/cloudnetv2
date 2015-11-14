m = require 'mithril'
ApplicationController = require 'controllers/application'
Servers = require 'models/servers'

class ServerController extends ApplicationController
  constructor: ->
    super
    @server = Servers.get m.route.param 'id'

  usages: ->
    stats = {
      'network_read': 0,
      'network_write': 0,
      'disk_read': 0,
      'disk_write': 0,
      'cpu': 0
    }
    return stats unless @server()
    @server().transactions.map (transaction) ->
      return if transaction.details.length < 50
      usages = JSON.parse transaction.details
      primary_disk = usages.disk_hourly_stats[0]
      network = usages.net_hourly_stats[0]
      cpu = usages.cpu_hourly_stats[0]
      stats['network_read'] += network.data_received
      stats['network_write'] += network.data_sent
      stats['disk_read'] += primary_disk.data_read
      stats['disk_write'] += primary_disk.data_written
      stats['cpu'] += cpu.cpu_time
    stats['network_read'] = Math.round stats['network_read'] / 1000
    stats['network_write'] = Math.round stats['network_write'] / 1000
    stats['disk_read'] = Math.round stats['disk_read'] / 1000
    stats['disk_write'] = Math.round stats['disk_write'] / 1000
    stats


module.exports = ServerController
