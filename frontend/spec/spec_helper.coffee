# Turn the logger off in test envs
Logger = require 'lib/logger'
Logger.level = Logger.OFF

global.env = 'TEST'

global.localStorage = {}

global.expect = require('chai').expect
global.sinon = require('sinon')


beforeEach ->
  global.sandbox = sinon.sandbox.create()

afterEach ->
  global.localStorage = {}
  sandbox.restore()

# Collection of general helpers
class SpecHelpers
  # Code here

module.exports = {
  SpecHelpers: SpecHelpers
}
