dom = require 'view_helper'

describe 'Front page', ->
  it 'should render the front page', ->
    dom.gotoPath('/')
    dom.ajaxStub([{
      '_id': 4,
      'label': 'Cloud.net Budget UK London Zone',
      'coords': [1, 2],
      'templates': [{
        '_id': 32,
        'datacentre_id': 4,
        'label': 'Arch Linux 2012.08 x86'
      }]
    }])
    dom.ajaxStub()
    dom.should.contain 'Cloud.net Budget UK London Zone (1,2)'
