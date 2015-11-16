dom = require 'dom_helper'

describe 'Home page', ->
  it 'should render the home page', (done) ->
    dom.load '/', ->
      dom.xhrResponseFor '/', {
        json: {
          status: {
            datacentres: 1
          }
        }
      }
      expect($('.content').text()).to.contain '1 Federation datacentres'
      done()
