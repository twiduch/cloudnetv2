# Here we are preparing for full, end-to-end integration tests that try to emulate the deployed production
# environment as closely as possible. We boot up the API, frontend, transactions daemon and worker process.
# Tests are run through a headless browser using phantomjs through the Capybara gem.

# Build the frontend JS, CSS, etc
print 'Building frontend ... '
output = `npm run production 2>&1`
puts output if $CHILD_STATUS.to_i > 0
puts 'done.'

ENV['RACK_ENV'] = 'test'
# vcap.me is managed by Cloud Foundry, so it should be reliable. It, and all its ssubdomains point to 127.0.0.1
ENV['CLOUDNET_DOMAIN'] = 'vcap.me'

# Capybara is the thing that wraps a headless browser and lets you click on things inside Rspec tests.
require 'capybara/poltergeist'
require 'capybara/rspec'
Capybara.default_max_wait_time = 15
Capybara.default_driver = :poltergeist
Capybara.app_host = 'http://www.vcap.me'
# This is because Capybara's app_host setting assumes an external website and therefore assumes port 80, but we're
# actually pointing to the local Capybara instance so we need to tell Capybara to include the port that it uses for
# the test server.
Capybara.always_include_port = true

# There are pros and cons to using Sidekiq's inline mode.
# Pros:
#   * that we don't need to boot up the Sidekiq server as a separate process
#   * we can stub out various parts of Sidekiq's code, namely the mailer
# Cons:
#   * Sidekiq's inline mode isn't how it works in production, so there could be subtle differences. The only one I can
#     think of at the moment is that
require 'sidekiq/testing'
Sidekiq::Testing.inline!

# Boot the application
base_dir = File.join File.dirname(__FILE__), '/../..'
require File.join base_dir, 'config/boot'
Cloudnet.check_onapp_api_version!

# Run the API server and frontend UI
config_ru = File.read File.join base_dir, '/config.ru'
# Clearly eval() is less than optimal, but it makes things so much easier in booting up the API server and the
# frontend, whilst still allowing the app to be stubbed.
Capybara.app = eval("Rack::Builder.new { #{config_ru} }") # rubocop:disable Lint/Eval

# Boot the Transactions Daemon
Thread.abort_on_exception = true
Thread.new do
  Transactions::Sync.run
end

# As little should be stubbed as possible in integration tests, but in order to retrieve links from emails, this is
# really the easiest way.
Mail.defaults do
  delivery_method :test
end

RSpec.configure do |c|
  c.mock_with :rspec
  c.expect_with :rspec
  c.color = true
  c.include Capybara::DSL

  c.before(:each) do
    Sidekiq::Worker.clear_all
    Mail::TestMailer.deliveries.clear
    # Ensure the DB is clean before each spec
    Mongoid.disconnect_clients
    Mongoid::Clients.default.database.drop
    print 'Updating Federation Resources ... '
    UpdateFederationResources.run
    puts 'done.'
  end
end
