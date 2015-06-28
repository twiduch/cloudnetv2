m = require 'mithril'

class Form
  constructor: ->
    # Update this to provide feedback that something is happening
    @submitText = m.prop()
    # Some HTML to show the result of form submission
    @feedback = m.prop()
    # Whether the form is in the process of being submitted
    @submissionInProgress = m.prop false
    # Has the form been successfully submitted without any errors?
    @successfullySubmitted = m.prop false

module.exports = Form
