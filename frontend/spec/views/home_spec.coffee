dom = require 'dom_helper'

describe 'Front page', ->
  it 'should render the front page', (done) ->
    dom.load '/', ->
      dom.xhrResponseFor '/datacentres', {
        json: [{
          '_id': 4,
          'label': 'Cloud.net Budget UK London Zone',
          'coords': [1, 2],
          'templates': [{
            '_id': 32,
            'datacentre_id': 4,
            'label': 'Arch Linux 2012.08 x86'
          }]
        }]
      }
      expect($('.content').text()).to.contain '1 Federation datacentres'
      done()
