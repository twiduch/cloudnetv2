m = require 'mithril'

class API
  mountPoint: 'http://localhost:9292'

  token: m.prop(localStorage.token)

  # is the user logged in?
  loggedIn: () ->
    !!@token()

  # trade credentials for a token
  login: (email, password) ->
    m.request({
      method: 'POST',
      url: @mountPoint + '/auth/login',
      data: { email: email, password: password },
      unwrapSuccess: (res) ->
        localStorage.token = res
        return res
    }).then(@token)

  # forget token
  logout: () ->
    @token(false)
    delete localStorage.token

  # signup on the server for new login credentials
  register: (email, password) ->
    m.request({
      method: 'POST',
      url: @mountPoint + '/auth/register',
      data: { email: email, password: password }
    })

  # ensure verify token is correct
  verify: (token) ->
    m.request({
      method: 'POST',
      url: @mountPoint + '/auth/verify',
      data: { token: token }
    })

  # get current user object
  user: () ->
    @req(@mountPoint + '/user')

  # Don't try to parse HTTP responses that are unlikely to contain JSON
  nonJsonErrors: (xhr) ->
    if xhr.status > 200
      JSON.stringify(xhr.responseText)
    else
      xhr.responseText

  # Handle an error response from the cloud.net API
  handleResponseError: (error) =>
    unless error
      window.flashMessage(
        "Can't connect to the Cloud.net API on #{@mountPoint}"
      )
    else
      if error.status == 401
        @originalRoute = m.route()
        m.route('/login')
    # Returning an empty array gives the views at least something to work with
    []

  # make an authenticated request
  req: (options) ->
    if typeof options == 'string'
      options = { method: 'GET', url: "#{@mountPoint}#{options}" }

    if @loggedIn()
      oldConfig = options.config || () -> {}
      options.config = (xhr) ->
        xhr.setRequestHeader "authoniceorization", "Bearer " + @token()
        oldConfig(xhr)

    m.request(options).then null, @handleResponseError


module.exports = new API
