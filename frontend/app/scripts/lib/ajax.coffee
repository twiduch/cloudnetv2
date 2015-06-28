m = require 'mithril'
Logger = require 'lib/logger'

class AJAX
  constructor: ->
    @token = m.prop(localStorage.token)
    @message = m.prop('Loading...')

  success: (result) ->
    @message 'Connected'
    Logger.info "AJAX success", result
    result

  error: (result) ->
    # If auth error, redirect
    if result.status == 401
      # @originalRoute = m.route()
      Logger.error "Unauthorised AJAX request", result.message.error
      m.route '/login'
    Logger.error "AJAX error", result.message.error
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
    oldConfig = options.config || ->
    options.config = (xhr) =>
      xhr.setRequestHeader "Authorization", "TOKEN " + @token()
      oldConfig xhr

    @ajax options

module.exports = AJAX
