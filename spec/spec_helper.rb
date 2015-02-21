ENV['RACK_ENV'] = 'test'

require File.expand_path('../../config/boot', __FILE__)

Bundler.require :test
require 'rack/test'
require 'webmock/rspec'
require 'sidekiq/testing'

Dir["#{Cloudnet.root}/spec/support/**/*.rb"].each { |f| require f }

RSpec.configure do |c|
  c.mock_with :rspec
  c.expect_with :rspec
  c.color = true

  # Emtpy the DB
  c.before(:each) do
    Mongoid.default_session.drop
  end
end
