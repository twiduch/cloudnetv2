m = require 'mithril'
simpleForm = require 'views/_partials/simple_form'

module.exports = (controller) ->
  [
    m 'h1', 'Login'
    simpleForm controller, {
      class: 'login-form',
      submitText: 'Login',
      submittingText: 'Logging in...',
      inputs: [
        {
          label: 'Email:',
          setter: controller.user.email,
          attributes: {
            required: true,
            type: 'email'
          }
        },
        {
          label: 'Password:',
          setter: controller.user.password,
          attributes: {
            required: true,
            type: 'password',
            minlength: 8
          }
        },
      ],
      submit: controller.login
    }
  ]
