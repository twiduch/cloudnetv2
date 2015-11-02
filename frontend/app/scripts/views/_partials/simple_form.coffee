# A simple form partial
helpers = require 'lib/helpers'
m = require 'mithril'

class SimpleForm
  # controller: Mithril controller
  # formSettings: Hash, see examples, eg; login form
  constructor: (controller, formSettings) ->
    defaults = {
      submitText: 'Submit',
      submittingText: 'Submitting...'
    }
    @formSettings = helpers.extend defaults, formSettings
    @controller = controller

  formWrapper: ->
    m '.small-4.small-centered.columns',
      m "form.#{@formSettings.class}", { onsubmit: @onsubmit(@controller, @formSettings) }, @formBody()
      m 'p.form-feedback', @controller.form.feedback() if @controller.form.feedback()

  formBody: ->
    return if @controller.form.successfullySubmitted()
    [
      @formInputs()
      if @controller.form.submissionInProgress()
        # To prevent accidental resubmission during submission
        m 'span.form-submitting', @formSettings.submittingText
      else
        m 'input[type=submit].button', { value: @formSettings.submitText }
    ]

  formInputs: ->
    @formSettings.inputs.map (input) ->
      className = "#{input.label.toLowerCase().replace(/\W/g, '')}-input"
      [
        m '.row.collapse.prefix-radius',
          m '.small-3.columns',
            m 'span.prefix', input.label
          m '.small-9.columns',
            m "input.#{className}", helpers.extend {
              oninput: m.withAttr('value', input.setter),
            }, input?.attributes
      ]

  onsubmit: ->
    (event) =>
      event.preventDefault()
      @controller.form.feedback ''
      @controller.form.submissionInProgress true
      # It's assumed that @formSettings.submit involves AJAX. In which case redraw is blocked
      # until completion, so force a redraw now.
      m.redraw()
      @formSettings.submit.bind(@controller)(event).then =>
        @controller.form.submissionInProgress false

module.exports = (controller, formSettings) ->
  form = new SimpleForm(controller, formSettings)
  form.formWrapper()
