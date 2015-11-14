module.exports.extend = (object, properties) ->
  for key, val of properties
    object[key] = val
  object

module.exports.formatTime = (dateTime) ->
  dateTime = new Date(dateTime)
  dateTime.toUTCString()
