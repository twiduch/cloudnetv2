# Cloud.net's logging
module Logging
  extend ActiveSupport::Concern

  included do
    # Shared global logger. Just `include Logger` whenever you need to log
    module Logger
      def logger
        @logger ||= Cloudnet.logger
      end
    end
  end

  class_methods do
    def logger
      @logger ||= choose_logger
      @logger.level = ::Logger::INFO if environment == 'production'
      @logger
    end

    def log_time_since_last_transactions_sync
      seconds = time_since_last_transactions_sync
      if seconds
        logger.info "#{seconds} seconds since last transaction sync"
      else
        logger.warn 'The Transactions Daemon has never been run'
      end
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

    private

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
  end
end
