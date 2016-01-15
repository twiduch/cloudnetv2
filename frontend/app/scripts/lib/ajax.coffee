m = require 'mithril'
NProgress = require 'nprogress'
Logger = require 'lib/logger'

class AJAX
  constructor: ->
    @token = m.prop(localStorage.token)
    @message = m.prop('Connecting to API...')
    @ajaxLoader()

  success: (result) ->
    @message 'API Connected'
    Logger.info 'AJAX success', result
    result

  error: (result) ->
    # If auth error, redirect
    if result.status == 401
      # @originalRoute = m.route()
      Logger.error 'Unauthorised AJAX request', result.message.error
      m.route '/login'
    Logger.error 'AJAX error', JSON.stringify result.message.error
    result

  # Central wrapper around Mithril's request method
  ajax: (options) ->
    # Handle non-JSON responses, such as when the server is not reached
    options.extract = (xhr) ->
      return '{"error":"No response text"}' unless xhr.responseText
      # Fragile but fast
      isJson = '"[{'.indexOf(xhr.responseText.charAt(0)) != -1
      if isJson then xhr.responseText else JSON.stringify xhr.responseText
    options.unwrapError = (res, xhr) =>
      @message 'Cannot connect to API' if xhr.status == 0
      error_in_result = res?.message?.error
      message = if error_in_result then res.message else {
        error: "Server Error: #{xhr.status} #{xhr.statusText} (#{res})"
      }
      { message: message }
    m.request(options).then(@success.bind(this), @error)

  # Make an authenticated request
  request: (options) ->
    if typeof options is 'string'
      options = { method: 'GET', url: options }
    oldConfig = options.config || -> undefined
    options.config = (xhr) =>
      xhr.setRequestHeader 'Authorization', 'TOKEN ' + @token()
      oldConfig xhr

    @ajax options

  # Monkey-patch m.request to display loader when necessary
  ajaxLoader: ->
    global.originalRequest = m.request
    global.pendingAJAXRequests = 0

    m.request = =>
      @onAJAXStarted() if pendingAJAXRequests == 0
      pendingAJAXRequests += 1

      promise = originalRequest.apply(null, arguments)
      decrement = =>
        pendingAJAXRequests -= 1
        @onAJAXFinished() if pendingAJAXRequests == 0
      promise.then(decrement, decrement)

      promise

  onAJAXStarted: ->
    NProgress.start()

  onAJAXFinished: ->
    NProgress.done()

module.exports = AJAX
