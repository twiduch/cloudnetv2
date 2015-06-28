m = require 'mithril'
api = require 'lib/api'

class User
  constructor: ->
    @fullName = m.prop()
    @email = m.prop()
    @password = m.prop()
    @passwordConfirm = m.prop()


module.exports = User
