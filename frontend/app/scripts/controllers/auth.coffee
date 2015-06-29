m = require 'mithril'
ApplicationController = require 'controllers/application'
User = require 'models/user'
Form = require 'models/form'

class AuthController extends ApplicationController
  constructor: ->
    super
    @user = new User
    @form = new Form

  register: ->
    @api.post(
      '/auth/register',
      {
        full_name: @user.fullName(),
        email: @user.email()
      }
    ).then(@registrationCallback.bind(this))

  registrationCallback: (response) ->
    if response.message?.error
      error = response.message.error
      if error.email
        message = "Email #{error.email}"
      else
        message = 'There was a problem registering, please try again.'
    else
      @form.successfullySubmitted true
      message = 'Thanks for registering. An email will be sent shortly.'
    @form.feedback message

  confirm: ->
    @api.put(
      '/auth/confirm', {
        token: m.route.param('token'),
        password: @user.password()
      }
    ).then(@confirmationCallback.bind(this))

  confirmationCallback: (response) ->
    if response.message?.error
      message = 'There was a problem with confirmation.'
    else
      message = [
        'Your account has been confirmed, please '
        m "a[href='/auth/login']", { config: m.route }, 'login'
      ]
      @form.successfullySubmitted true
    @form.feedback message

  login: ->
    @api.login(@user.email(), @user.password()).then(
      (result) =>
        unless result
          @form.feedback 'There was a problem logging in'
        else
          @form.successfullySubmitted true
    )

module.exports = AuthController
