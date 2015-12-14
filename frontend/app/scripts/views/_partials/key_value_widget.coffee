m = require 'mithril'
helpers = require 'lib/helpers'

module.exports = (hash) ->
  for key, value of hash
    selectorForValue = helpers.toSlug "keyvalues-#{key}-value"
    [
      m '.row',
        m 'strong.small-2.columns', key
        m ".small-6.columns.end.#{selectorForValue}", value
    ]
