require 'dotenv'
Dotenv.load

require 'rubygems'
require 'bundler/setup'

require 'sentry-raven'
require 'logglier'

ENV['NEW_RELIC_FRAMEWORK'] = 'ruby'
require 'newrelic_rpm'

# Manually require gems, rather than use `Bundler.require`, to save startup time
require 'sidekiq/api'
require 'mongoid'
require 'mongoid-paranoia'
require 'mongoid-history'
require 'grape'
require 'grape-swagger'
require 'grape-roar'

I18n.enforce_available_locales = false

require_relative './setup/setup'

Sidekiq::Logging.logger = Cloudnet.logger

Raven.configure do |config|
  config.dsn = ENV['SENTRY_DSN_WITH_SECRET']
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
