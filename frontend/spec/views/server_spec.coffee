dom = require 'dom_helper'

describe 'Front page', ->
  it 'should render a server page', (done) ->
    dom.load '/servers/123', ->
      dom.xhrResponseFor '/servers/123', {
        json: {
          id: 123,
          name: 'Test Server',
          template: {
            id: 32,
            datacentre_id: 4,
            label: 'Arch Linux 2012.08 x86'
          },
          ip_address: '1.2.3.4',
          transactions: [{
            date: 'Wed, 04 Nov 2015 07:59:43 GMT',
            details: '{
              "disk_hourly_stats": [{
                "data_read": 1234123,
                "data_written": 4123
              }],
              "net_hourly_stats": [{
                "data_received": 98763,
                "data_sent": 1234123
              }],
              "cpu_hourly_stats": [{
                "cpu": 3478
              }]
            }'
          }]
        }
      }
      expect($('.content').text()).to.contain 'IP Address1.2.3.4'
      expect($('.content').text()).to.contain 'DiskRead: 1234k'
      done()
