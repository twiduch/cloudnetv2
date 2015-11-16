m = require 'mithril'
header = require 'views/layout/header'

module.exports = (content) ->
  (controller) ->
    [
      header(controller)
      m '.content.row', content(controller)
      m 'footer.row',
        m '.small-12.columns', 'Copyright ©2015 cloud.net'
    ]
