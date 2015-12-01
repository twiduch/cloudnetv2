ruby '2.2.3'
source 'https://rubygems.org'

# Load ENV from .env file
gem 'dotenv'

# Log errors to app.getsentry.com
gem 'sentry-raven'

# Application monitoring
gem 'newrelic_rpm' # The actual NewRelic gem
gem 'newrelic-grape' # Grape-specific implementation application traces

# Allow cross-origin incoming HTTP requests
gem 'rack-cors', require: 'rack/cors'
# Web server
gem 'puma'

# Mongo ORM
gem 'mongoid'
# Soft delete records
gem 'mongoid_paranoia'
gem 'bcrypt' # Requirement of Mongoid, but why?
gem 'symmetric-encryption'

# API
gem 'grape'
# For presenting lovely serialised API responses of objects
gem 'grape-roar'
# Auto-generate API documentation
gem 'grape-swagger'

# Worker jobs
gem 'sidekiq'

# General purpose HTTP client. Used to communicate with Onapp API
gem 'faraday'

# For sending email
gem 'mail'

# HACK: Devise and Active Admin seem to need to be required here when run from rake. Whereas when run from config.ru
# they can be loaded later.
# Either way, the point is that we're trying to require as little as possible to save on boot up times.
require_for_asset_compilation = ENV['ASSET_COMPILATION'] == 'true'
# Only used for Active Admin
gem 'rails', require: false
gem 'devise', require: require_for_asset_compilation
# Watch https://github.com/activeadmin/activeadmin/issues/2714
gem 'activeadmin', github: 'Zhomart/active_admin', branch: 'mongoid-old', require: require_for_asset_compilation

# Fancy console
gem 'pry'
gem 'pry-byebug'
gem 'pry-doc'

# CLI tasks
gem 'rake'

group :development do
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-puma'
  gem 'rb-inotify'
end

group :test do
  gem 'rspec'
  gem 'rack-test'
  gem 'fabrication'
  gem 'webmock'
  gem 'vcr'
  gem 'timecop'
  gem 'rubocop'
  gem 'codeclimate-test-reporter', require: nil
end
