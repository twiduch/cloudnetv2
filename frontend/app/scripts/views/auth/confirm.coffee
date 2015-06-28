m = require 'mithril'
simpleForm = require 'views/_partials/simple_form'

module.exports = (controller) ->
  [
    m 'h1', 'Confirm'
    simpleForm controller, {
      class: 'login-form'
      submitText: 'Confirm',
      submittingText: 'Confirming...',
      inputs: [
        {
          label: 'Password:',
          setter: controller.user.password
          attributes: {
            type: 'password'
            minlength: 8
          }
        },
        {
          label: 'Password Confirm:',
          setter: controller.user.passwordConfirm
          attributes: {
            type: 'password'
            onkeyup: ->
              if (controller.user.passwordConfirm() != controller.user.password())
                this.setCustomValidity 'Password must be matching.'
              else
                this.setCustomValidity('')
          }
        }
      ],
      submit: controller.confirm
    }
  ]
