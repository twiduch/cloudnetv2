dom = require 'view_helper'
api = require 'lib/api'

describe 'API requests', ->
  it 'should make a GET request', ->
    request = ''
    api.get('/spec/path').then (response) ->
      request = response
    dom.ajaxStub()
    expect(request.method).to.eq 'GET'
    expect(request.url).to.eq "#{api.constructor.base}/spec/path"

  it 'should make a GET request and parse the response', ->
    expectedResponse = ''
    api.get('/spec/path').then (response) ->
      expectedResponse = response
    dom.ajaxStub({ foo: 'bar' })
    expect(expectedResponse.foo).to.eq 'bar'

  it 'should make a POST request', ->
    request = ''
    api.post('/spec/path', {foo: 'bar'}).then (response) ->
      request = response
    dom.ajaxStub()
    expect(request.method).to.eq 'POST'
    expect(request.url).to.eq "#{api.constructor.base}/spec/path"
    # TODO: check for body. Need to update mithril's AJAX stub

  it 'should make a POST request and parse the response', ->
    expectedResponse = ''
    api.post('/spec/path').then (response) ->
      expectedResponse = response
    dom.ajaxStub({ foo: 'bar' })
    expect(expectedResponse.foo).to.eq 'bar'
