require 'dotenv'
Dotenv.load

require 'rubygems'
require 'bundler/setup'

# Manually require gems, rather than use `Bundler.require` to save startup time
require 'sidekiq/api'
require 'mongoid'
require 'grape'
require 'grape-entity'
require 'grape-swagger'

I18n.enforce_available_locales = false

require_relative './settings'

unless File.exist? Cloudnet.root + '.env'
  fail 'Preventing boot because of missing .env file'
end

Mongoid.load!(Cloudnet.root + '/config/mongoid.yml')

Cloudnet.init
