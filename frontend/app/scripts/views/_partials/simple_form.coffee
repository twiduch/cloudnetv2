# A simple form partial

helpers = require 'lib/helpers'
m = require 'mithril'

module.exports = (controller, formSettings) ->
  # Set defaults
  defaults = {
    submitText: 'Submit',
    submittingText: 'Submitting...'
  }
  formSettings = helpers.extend defaults, formSettings

  [
    m "form.#{formSettings.class}", {
      onsubmit: (e) ->
        e.preventDefault()
        controller.form.feedback ''
        controller.form.submissionInProgress true
        # It's assumed that formSettings.submit involves AJAX. In which case redraw is blocked
        # until completion, so force a redraw now.
        m.redraw()
        formSettings.submit.bind(controller)(e).then ->
          controller.form.submissionInProgress false
    },

    # The actual form
    unless controller.form.successfullySubmitted()
      [
        formSettings.inputs.map (input) ->
          className = "#{input.label.toLowerCase().replace(/\W/g, '')}-input"
          [
            m 'label', input.label
            m "input.#{className}", helpers.extend {
              oninput: m.withAttr('value', input.setter),
            }, input?.attributes
          ]
        if controller.form.submissionInProgress()
          # To prevent accidental resubmission during submission
          m 'span.form-submitting', formSettings.submittingText
        else
          m 'input[type=submit]', { value: formSettings.submitText }
      ]

    # Feedback of success or validation errors
    if controller.form.feedback()
      m 'p.form-feedback', controller.form.feedback()

  ]
