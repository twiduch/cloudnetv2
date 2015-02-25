source 'https://rubygems.org'

gem 'dotenv'

gem 'rack-cors', require: 'rack/cors'
gem 'puma'
gem 'mongoid'
gem 'grape'
gem 'grape-entity'
gem 'grape-swagger' # Auto-generate API documentation
gem 'sidekiq'
# General purpose API wrapper. Used to communicate with Onapp API
gem 'blanket_wrapper', require: 'blanket'

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
  gem 'rubocop'
  gem 'codeclimate-test-reporter', require: nil
end
