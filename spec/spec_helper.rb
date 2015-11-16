ENV['RACK_ENV'] = 'test'

ENV['ONAPP_URI'] = 'https://localhost'
ENV['ONAPP_USER'] = 'test'
ENV['ONAPP_PASS'] = 'test'
ENV['ONAPP_CLOUDNET_ROLE'] = '2'

require File.expand_path('../../config/boot', __FILE__)

Bundler.require :test
require 'rack/test'
require 'webmock/rspec'
require 'sidekiq/testing'

Cloudnet.recursive_require 'spec/support'

# Ugly hack to avoid VCR bug. Watch https://github.com/vcr/vcr/issues/521
module VCR
  def dup_context(context)
    {
      turned_off: context[:turned_off],
      ignore_cassettes: (context[:ignore_cassettes].dup if context[:ignore_cassettes]),
      cassettes: context[:cassettes].dup
    }
  end
end

Mail.defaults do
  delivery_method :test
end

RSpec.configure do |c|
  c.mock_with :rspec
  c.expect_with :rspec
  c.color = true

  c.before(:each) do
    Mail::TestMailer.deliveries.clear
    # Make sure all worker jobs are processed immediately, unless told otherwise
    Sidekiq::Testing.inline!
    # Ensure the DB is clean before each spec
    Mongoid.disconnect_clients
    Mongoid::Clients.default.database.drop
  end

  c.before(:each) do
    Sidekiq::Worker.clear_all
  end
end
