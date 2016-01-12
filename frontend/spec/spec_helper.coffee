require 'coverage_helper'

# Turn the logger off in test envs
Logger = require 'lib/logger'
Logger.level = Logger.OFF

global.env = 'TEST'

global.localStorage = {}

global.expect = require('chai').expect

# Sinon is used for spies, mocks, fake HTTP requests, etc
# Stub XMLHttpRequest until jsdom creates the window object in before hooks
global.XMLHttpRequest = ->
  true
global.sinon = require('sinon')
# Sinon has an annoying issue where XHR errors are raised after everything finishes, you have to manually set this flag
# to get hard errors raised immediately. Follow: https://github.com/sinonjs/sinon/issues/172
sinon.logError.useImmediateExceptions = true

beforeEach ->
  # Just a sandbox for cleanly working with spies, etc
  global.sandbox = sinon.sandbox.create()

afterEach ->
  sandbox.restore()

# Collection of general helpers
class SpecHelpers
  #

module.exports = {
  SpecHelpers: SpecHelpers
}
