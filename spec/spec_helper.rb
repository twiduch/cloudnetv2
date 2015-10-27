ENV['RACK_ENV'] = 'test'

require File.expand_path('../../config/boot', __FILE__)

Bundler.require :test
require 'rack/test'
require 'webmock/rspec'
require 'sidekiq/testing'

Cloudnet.recursive_require 'spec/support'

Mail.defaults do
  delivery_method :test
end

RSpec.configure do |c|
  c.mock_with :rspec
  c.expect_with :rspec
  c.color = true

  c.before(:each) do
    Mongoid.disconnect_sessions
    Mongoid.default_session.drop
    Mail::TestMailer.deliveries.clear
    # Make sure all worker jobs are processed immediately, unless told otherwise
    Sidekiq::Testing.inline!
  end

  c.before(:each) do
    Sidekiq::Worker.clear_all
  end
end
