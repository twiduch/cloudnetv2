m = require 'mithril'

module.exports = (hash) ->
  for key, value of hash
    [
      m '.row',
        m 'strong.small-2.columns', key
        m '.small-6.columns.end', value
    ]
