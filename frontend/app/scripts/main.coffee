global.env ||= 'DEV' if document.location.hostname == 'localhost'

integration_tests = true if document.location.hostname == 'www.vcap.me'

unless global.env == 'DEV' || global.env == 'TEST' || integration_tests
  # Report errors to app.getsentry.com
  Raven = require 'raven-js'
  # A browserify transform will add the DSN URI from the ENV
  Raven.config('SENTRY_DSN').install()

m = require 'mithril'
layout = require 'views/layout/layout'

Logger = require 'lib/logger'
Logger.level = Logger.DEBUG if global.env == 'DEV'

api = require 'lib/api'


# Convert something like {a: {b: 'value'}} to {'a/b': 'value'}
# Provides compatibility with the `require-globify` syntax
deepHashToSlashes = (hash, newHash, newKeyParts) ->
  rootLevel = typeof newHash is 'undefined'
  newHash = newHash || {}
  newKeyParts = newKeyParts || []
  Object.keys(hash).map (key) ->
    newKeyParts = [] if rootLevel
    if typeof hash[key] is 'function'
      newKey = (newKeyParts.concat(key)).join('/')
      newHash[newKey] = hash[key]
    else
      newKeyParts.push key
      deepHashToSlashes hash[key], newHash, newKeyParts
  newHash

# Preload all controllers and views and save them to a hash for referencing later.
# We need to use different require modules depending on the environment. `require-globify` doesn't
# work without browserify (browserify isn't run by mocha), so we use `require-dir` instead.
# And `require-dir` doesn't work in the browser (because of differences in commonjs, namely the
# missing require.resolve function), so we use `require-globify` instead.
if global.env == 'TEST'
  require 'coffee-script/register'
  requireDir = require 'require-dir'
  controllersHash = requireDir 'controllers', recurse: true
  viewsHash = requireDir 'views', recurse: true
  # Converts something like { auth: {login: function()}} to {'auth/login': function()}
  controllers = deepHashToSlashes controllersHash
  views = deepHashToSlashes viewsHash
else
  controllers = require 'controllers/*.coffee', {mode: 'hash'}
  views = require 'views/**/*.coffee', {mode: 'hash'}

# Wrap a view in the layout view
withLayout = (Controller, view) ->
  controller: Controller
  view: layout(view)

route = (name) ->
  parts = name.split '/'
  controller = parts[0]
  view = name
  withLayout(controllers[controller], views[view])

# Check if user is logged in
api.verifyToken()

# Kind of a hacky way to provide the ability of programatically loading a route during testing
defaultRoute = global.windowPath || '/'

m.route.mode = 'pathname'
m.route(document.body, defaultRoute, {
  '/': route('home'),
  '/dashboard': route('dashboard'),
  '/servers/:id': route('servers'),
  '/auth/register': route('auth/register'),
  '/auth/login': route('auth/login'),
  '/auth/confirm': route('auth/confirm')
})
