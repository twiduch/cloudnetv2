require 'dotenv'
Dotenv.load

require 'rubygems'
require 'bundler/setup'

require 'sentry-raven'

require 'newrelic_rpm'
require 'newrelic-grape'

# Manually require gems, rather than use `Bundler.require` to save startup time
require 'sidekiq/api'
require 'mongoid'
require 'mongoid-paranoia'
require 'grape'
require 'grape-swagger'
require 'grape-roar'

I18n.enforce_available_locales = false

require_relative './settings'

Raven.configure do |config|
  config.dsn = ENV['SENTRY_DSN']
end if Cloudnet.environment == 'production' || Cloudnet.environment == 'staging'
unless Cloudnet.environment == 'production' || ENV['CONTINUOUS_INTEGRATION'] == 'true'
  unless File.exist? Cloudnet.root + '.env'
    fail 'Preventing boot because of missing .env file'
  end
end

Mongoid.load!(Cloudnet.root + '/config/mongoid.yml')
Mongoid.logger.level = Logger::INFO
Mongo::Logger.logger.level = Logger::INFO

Cloudnet.init
