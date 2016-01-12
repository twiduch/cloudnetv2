# Base Cloudnet settings
module Cloudnet
  # Our API version
  VERSION = '2.0.0'

  # The version of OnApp's API which this code is currently tested against
  ONAPP_API_VERSION = '4.1.0'

  # Root path of the project on the host filesystem
  ROOT_PATH = File.join(File.dirname(__FILE__), '../')

  # The OnApp API has various permissions, eg; CRUD servers, CRUD DNS, etc. This is the official
  # list of those permissions that make using cloud.net possible.
  ONAPP_USER_PERMISSIONS = [
    7, 32, 34, 36, 38, 40, 46, 53, 87, 89, 91, 93, 96, 105, 106, 107, 117, 130, 134, 135, 137,
    139, 140, 142, 144, 146, 148, 149, 153, 155, 160, 190, 192, 194, 196, 201, 221, 222, 237,
    244, 247, 249, 250, 260, 265, 267, 269, 276, 288, 291, 293, 295, 297, 305, 307, 309, 314,
    318, 329, 337, 338, 348, 349, 354, 355, 358, 360, 362, 364, 376, 437, 442, 461, 463, 465,
    489, 495, 497, 498, 499, 500, 501, 502, 504, 508, 510, 512, 513, 514, 517, 520, 522, 524,
    525, 528, 530, 532, 533, 537, 539, 541, 547, 550
  ]

  # Keep track of the current user in order to record a paper trail of changes to critical data.
  # Can be set when a user authenticates with the API. There are also users like :workerbot and :syncdaemon.
  DEFAULT_MODIFIER = :ruby
  @current_user ||= DEFAULT_MODIFIER

  class << self
    attr_accessor :current_user

    def init
      # So you can just use `require 'project/file'`
      $LOAD_PATH.unshift(root)
      require_app
      check_version
      ensure_db_seeded
      log_active_sidekiq_ps
      log_time_since_last_transactions_sync
    end

    def recursive_require(path, use_load: false)
      Dir["#{root}/#{path}/**/*.rb"].each do |file|
        if use_load
          load file
        else
          require file
        end
      end
    end

    def require_app(use_load: false)
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

    # The base domain for the HTTP frontend
    def hostname
      ENV['CLOUDNET_DOMAIN'] || 'localhost'
    end

    def logger
      @logger ||= choose_logger
      @logger.level = ::Logger::INFO if environment == 'production'
      @logger
    end

    def choose_logger
      case Cloudnet.environment
      when 'test'
        ::Logger.new '/dev/null'
      when 'production', 'staging'
        Logglier.new ENV['LOGGLY_URI'], threaded: true
      else
        ::Logger.new STDOUT
      end
    end

    # OnApp has various roles with differeing levels of permissions. Here we have the role ID
    # for the role created specifically for cloud.net users.
    def onapp_cloudnet_role
      role = ENV['ONAPP_CLOUDNET_ROLE']
      fail "Invalid OnApp role ID: #{role}" if role.nil? || (role.to_i < 1)
      role
    end

    # Check for API version mismatch.
    def check_version
      return if ENV['DISABLE_HTTP_CHECKS'] == 'true'
      # Version mismatch is checked differently during testing.
      return if Cloudnet.environment == 'test' || ENV['SKIP_ONAPP_API_CHECK']
      Cloudnet.logger.info 'Checking OnApp version...'
      onapp_api_version = OnappAPI.admin(:get, '/version')['version']
      return if onapp_api_version == Cloudnet::ONAPP_API_VERSION
      Cloudnet.logger.warn "OnApp API version (#{onapp_api_version}) differs from version that " \
                           "cloud.net is tested against (#{Cloudnet::ONAPP_API_VERSION})"
    end

    # Ensure DB is seeded/updated with the available datacentres. Cloudnet is useless otherwise!
    def ensure_db_seeded
      return unless Cloudnet.environment != 'test' && Datacentre.all.count == 0
      UpdateFederationResources.run
    end

    def log_active_sidekiq_ps
      ps = Sidekiq::ProcessSet.new
      logger.info "#{ps.size} active Sidekiq process(es)"
    end

    def time_since_last_transactions_sync
      last_sync = System.get(:transactions_last_sync_attempt)
      return :never_synced if last_sync == ''
      Time.now.to_i - last_sync.to_i
    end

    def log_time_since_last_transactions_sync
      seconds = time_since_last_transactions_sync
      if seconds
        logger.info "#{seconds} seconds since last transaction sync"
      else
        logger.warn 'The Transactions Daemon has never been run'
      end
    end
  end

  # Shared global logger. Just `include Logger` whenever you need to log
  module Logger
    def logger
      @logger ||= Cloudnet.logger
    end
  end
end
