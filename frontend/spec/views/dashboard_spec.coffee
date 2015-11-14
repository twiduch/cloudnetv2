dom = require 'dom_helper'

describe 'Front page', ->
  it 'should render the dashboard', (done) ->
    dom.load '/dashboard', ->
      dom.xhrResponseFor '/servers', {
        json: [{
          'id': 'abc123',
          'name': 'Test Server',
          'hostname': 'testserver',
          'template': {
            '_id': 32,
            'datacentre_id': 4,
            'label': 'Arch Linux 2012.08 x86'
          }
        }]
      }
      expect($('.content table ').text()).to.contain 'Test Server'
      done()
