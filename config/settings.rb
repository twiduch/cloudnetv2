# Base Cloudnet settings
module Cloudnet
  # Our API version
  VERSION = '2.0.0'

  # The version of OnApp's API which this code is currently tested against
  ONAPP_API_VERSION = '3.4.0'

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

  class << self
    def init
      # Add project root to require's default paths
      $LOAD_PATH.unshift(root)
      [
        'config/initialisers',
        'lib',
        'app'
      ].each { |path| recursive_require path }
    end

    def recursive_require(path)
      Dir["#{root}/#{path}/**/*.rb"].each { |f| require f }
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
      ENV['DOMAIN'] || 'localhost'
    end

    def logger
      output = Cloudnet.environment == 'test' ? '/dev/null' : STDOUT
      @logger ||= ::Logger.new output
    end

    # OnApp has various roles with differeing levels of permissions. Here we have the role ID
    # for the role created specifically for cloud.net users.
    def onapp_cloudnet_role
      role = ENV['ONAPP_CLOUDNET_ROLE']
      fail "Invalid OnApp role ID: #{role}" if role.nil? || (role.to_i < 1)
      role
    end
  end

  # Shared global logger. Just `include Logger` whenever you need to log
  module Logger
    def logger
      @logger ||= Cloudnet.logger
    end
  end
end
