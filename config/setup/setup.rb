require_relative 'onapp_checks'
require_relative 'logging'

# Cloud.net setup
module Cloudnet
  include OnappChecks
  include Logging

  # Our API version
  VERSION = '2.0.0'

  # Root path of the project on the host filesystem
  ROOT_PATH = File.join(File.dirname(__FILE__), '../../')

  # Keep track of the current user in order to record a paper trail of changes to critical data.
  # Can be set when a user authenticates with the API. There are also users like :workerbot and :syncdaemon.
  DEFAULT_MODIFIER = :ruby
  @current_user ||= DEFAULT_MODIFIER

  # The number of seconds within in which it is expected that a server should boot
  SERVER_BUILD_MAX_WAIT = 5 * 60

  class << self
    attr_accessor :current_user

    def init
      $LOAD_PATH.unshift(root) # So you can just use `require 'project/file'`
      require_app_files
      check_onapp_api_version
      ensure_db_seeded
      log_active_sidekiq_ps
      log_time_since_last_transactions_sync
    end

    def recursive_require(path, use_load: false)
      Dir["#{root}/#{path}/**/*.rb"].each do |file|
        if use_load
          # load() is useful for quickly refreshing changed code during development
          load file
        else
          require file
        end
      end
    end

    def require_app_files(use_load: false)
      require_order.each { |path| recursive_require path, use_load: use_load }
    end

    def require_order
      [ 'config/initialisers',
        'lib/build_checker_daemon/data',
        'lib/build_checker_daemon/builder',
        'lib',
        'app'
      ]
    end

    # Alias for ROOT_PATH
    def root
      ROOT_PATH
    end

    # Environment, normally one of: 'production', 'development', 'test'
    def environment
      ENV['RACK_ENV'] || 'production'
    end

    def debug?
      ENV['DEBUG'] || false
    end

    # The base domain for the HTTP frontend. Used by things like email templates
    def hostname
      ENV['CLOUDNET_DOMAIN'] || 'localhost'
    end

    # Ensure DB is seeded/updated with the available datacentres. Cloudnet is useless otherwise!
    def ensure_db_seeded
      return unless Cloudnet.environment != 'test' && Datacentre.synchronised?
      UpdateFederationResources.run
    end
  end
end
