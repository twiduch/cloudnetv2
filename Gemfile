source 'https://rubygems.org'

# Load ENV from .env file
gem 'dotenv'

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
gem 'grape', github: 'intridea/grape'
# For presenting lovely serialised API responses of objects
gem 'grape-roar'
# Auto-generate API documentation
gem 'grape-swagger'

# Worker jobs
gem 'sidekiq'

# General purpose API wrapper. Used to communicate with Onapp API
gem 'blanket_wrapper', require: 'blanket'
gem 'mail'

# Only used for Active Admin
gem 'rails', require: false
gem 'devise', require: false
# Watch https://github.com/activeadmin/activeadmin/issues/2714
gem 'activeadmin', github: 'Zhomart/active_admin', branch: 'mongoid-old', require: false

# Fancy console
gem 'pry'
gem 'pry-byebug'

gem 'rake'

group :development do
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-puma'
  gem 'rb-inotify', require: false
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
