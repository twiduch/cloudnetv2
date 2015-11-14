m = require 'mithril'
AJAX = require 'lib/ajax'
Logger = require 'lib/logger'

# Communicate with the cloud.net API.
# Note that all responses return JS promises.
class API
  @base = if document.location.hostname.indexOf('localhost') >= 0
    'http://api.localhost:9393'
  else
    "http://#{document.location.hostname}".replace 'www.', 'api.'

  constructor: ->
    @ajax = new AJAX
    @currentUser = m.prop false

  # Trade credentials for a token
  login: (email, password) ->
    params = { email: email, password: password }
    @get('/auth/token', params).then @setUser.bind(this)

  setUser: (result) ->
    return false unless result.login_token
    @currentUser result
    localStorage.token = result.login_token
    @ajax.token result.login_token
    Logger.info "Login success. Token: #{result.login_token}"
    true

  logout: =>
    @ajax.token false
    delete localStorage.token
    @currentUser false
    m.route '/'

  verifyToken: ->
    if localStorage.token
      @fromVerification = true
      @get('/auth/verify').then @setUser.bind(this)

  get: (path, params) ->
    @request 'GET', path, params

  post: (path, params) ->
    @request 'POST', path, params

  put: (path, params) ->
    @request 'PUT', path, params

  request: (method, path, params) ->
    options = {
      method: method,
      url: "#{@constructor.base}#{path}",
      data: params
    }
    @ajax.request(options)

module.exports = new API
