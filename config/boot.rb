require 'dotenv'
Dotenv.load

require 'rubygems'
require 'bundler/setup'

Bundler.require :default, ENV['RACK_ENV']

I18n.enforce_available_locales = false

require_relative './settings'

unless File.exist? Cloudnet.root + '.env'
  fail 'Preventing boot because of missing .env file'
end

Mongoid.load!(Cloudnet.root + '/config/mongoid.yml')

# Add the project path to Ruby's library path for easy require()'ing
$LOAD_PATH.unshift(Cloudnet.root)

Dir["#{Cloudnet.root}/lib/**/*.rb"].each { |f| require f }
Dir["#{Cloudnet.root}/app/**/*.rb"].each { |f| require f }

# Check for API version mismatch.
# Version mismatch is checked differently during testing.
unless Cloudnet.environment == 'test'
  onapp_api_version = OnappAPI.admin_connection.get(:version).version
  if onapp_api_version != Cloudnet::ONAPP_API_VERSION
    Cloudnet.logger.warn "OnApp API version (#{onapp_api_version}) differs from version that " \
                         "cloud.net is tested against (#{Cloudnet::ONAPP_API_VERSION})"
  end
end

# Ensure DB is seeded/updated with the available datacentres. Cloudnet is useless otherwise!
if Cloudnet.environment != 'test' && Datacentre.all.count == 0
  UpdateFederationResources.run
end
