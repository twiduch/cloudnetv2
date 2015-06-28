m = require 'mithril'
AJAX = require 'lib/ajax'
Logger = require 'lib/logger'

# Communicate with the cloud.net API.
# Note that all responses return JS promises.
class API
  @base = 'http://localhost:9393'

  constructor: ->
    @ajax = new AJAX
    @currentUser = m.prop false

  # Trade credentials for a token
  login: (email, password) ->
    params = { email: email, password: password }
    @get('/auth/token', params).then @setUser.bind(this)

  setUser: (result) ->
    if result.token
      localStorage.token = result.token
      @ajax.token result.token
      m.route '/dashboard'
      Logger.info "Login success. Token: #{result.token}"
    if result.user
      @currentUser result.user

  logout: =>
    @ajax.token false
    delete localStorage.token
    @currentUser false
    m.route '/'

  # Ensure token is valid
  verifyToken: ->
    if localStorage.token
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
