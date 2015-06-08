api = require 'lib/api'

describe 'API requests', ->
  it 'should make a GET request', ->
    request = ''
    api.get('spec/path').then (response) ->
      request = response
    SpecHelpers.ajaxReturnRequestAsResponse()
    expect(request.method).toEqual 'GET'
    expect(request.url).toEqual "#{api.constructor.base}/spec/path"

  it 'should make a GET request and parse the response', ->
    expectedResponse = ''
    api.get('spec/path').then (response) ->
      expectedResponse = response
    SpecHelpers.ajaxResponse({ foo: 'bar' })
    expect(expectedResponse.foo).toEqual 'bar'

  it 'should make a POST request', ->
    request = ''
    api.post('spec/path', {foo: 'bar'}).then (response) ->
      request = response
    SpecHelpers.ajaxReturnRequestAsResponse()
    expect(request.method).toEqual 'POST'
    expect(request.url).toEqual "#{api.constructor.base}/spec/path"
    # TODO: check for body

  it 'should make a POST request and parse the response', ->
    expectedResponse = ''
    api.post('spec/path').then (response) ->
      expectedResponse = response
    SpecHelpers.ajaxResponse({ foo: 'bar' })
    expect(expectedResponse.foo).toEqual 'bar'
