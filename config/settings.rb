# Base Cloudnet settings
module Cloudnet
  VERSION = '0.0.1'

  # Root path of the project on the host filesystem
  ROOT_PATH = File.join(File.dirname(__FILE__), '../')

  # Alias for ROOT_PATH
  def self.root
    ROOT_PATH
  end

  # Environment, normally one of: 'production', 'development', 'test'
  def self.environment
    ENV['RACK_ENV'] || 'production'
  end

  def self.debug?
    ENV['DEBUG'] || false
  end

  def self.logger
    output = Cloudnet.environment == 'test' ? '/dev/null' : STDOUT
    output = STDOUT if Cloudnet.debug?
    @logger ||= ::Logger.new output
  end

  # Shared global logger
  module Logger
    def logger
      @logger ||= Cloudnet.logger
    end
  end
end
