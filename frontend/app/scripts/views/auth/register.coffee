m = require 'mithril'
simpleForm = require 'views/_partials/simple_form'

module.exports = (controller) ->
  [
    m 'h1', 'Register'
    simpleForm controller, {
      class: 'login-form',
      submitText: 'Register',
      submittingText: 'Registering...',
      inputs: [
        {
          label: 'Full name:',
          setter: controller.user.fullName,
          attributes: {
            required: true,
            type: 'text'
          }
        },
        {
          label: 'Email:',
          setter: controller.user.email,
          attributes: {
            required: true,
            type: 'email'
          }
        }
      ],
      submit: controller.register
    }
  ]
