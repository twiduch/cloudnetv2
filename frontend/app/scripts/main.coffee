m = require 'mithril'
layout = require 'views/layout/layout'

Logger = require 'lib/logger'

global.env ||= 'DEV' if document.location.hostname == "localhost"

Logger.level = Logger.DEBUG if global.env == 'DEV'

# Preload all controllers and views and savee them to a hash for referencing later.
# We need to use different require modules depending on the environment. `require-globify` doesn't
# work without browserify (browserify isn't run by jasmine-node), so we use `require-dir` instead.
# And `require-dir` doesn't work in the browser (because of differences in commonjs, namely the
# missing require.resolve function), so we use `require-globify` instead.
if global.env == 'TEST'
  require 'coffee-script/register'
  requireDir = require 'require-dir'
  controllers = requireDir 'controllers'
  views = requireDir 'views'
else
  controllers = require 'controllers/*.coffee', {mode: 'hash'}
  views = require 'views/*.coffee', {mode: 'hash'}

# Wrap a view in the layout view
withLayout = (Controller, view) ->
  controller: Controller
  view: layout(view)

route = (name) ->
  withLayout( controllers[name], views[name] )

m.route.mode = 'pathname'
m.route(document.body, "/", {
  "/": route('front'),
})
