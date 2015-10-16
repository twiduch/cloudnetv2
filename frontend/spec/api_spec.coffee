dom = require 'dom_helper'

describe 'API requests', ->

  before ->
    @api = require 'lib/api'

  it 'should make a GET request and parse the response', (done) ->
    @api.get('/spec/path').then (response) ->
      expect(response.foo).to.eq 'bar'
      done()
    request = dom.xhrResponseFor('/spec/path', { json: { foo: 'bar' } })
    expect(request.method).to.eq 'GET'
    expect(request.url).to.eq "#{@api.constructor.base}/spec/path"

  it 'should make a POST request', (done) ->
    @api.post('/spec/path', {question: 'foo'}).then (response) ->
      expect(response.answer).to.eq 'bar'
      done()
    request = dom.xhrResponseFor('/spec/path', { json: { answer: 'bar' } })
    expect(request.method).to.eq 'POST'
    expect(request.url).to.eq "#{@api.constructor.base}/spec/path"
