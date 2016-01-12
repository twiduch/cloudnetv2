module BuildChecker
  module ResultUpdater
    # Polling DB for server build information
    class Monitor
      include BuildCheckerData
      attr_reader :build_data, :server, :result
      DB_CHECK_EVERY = 15.seconds # Polling DB. Updates by transaction daemon

      def self.monitor_test_vm(build_data)
        new(build_data).monitor_test_vm
      end

      def initialize(build_data)
        @build_data = build_data
        @server = build_data.server
      end

      def monitor_test_vm
        sleep DB_CHECK_EVERY until build_ended?
        result
      end

      def build_ended?
        build_succeded? || build_failed? || build_timeout?
      end

      # TODO: transaction checker should report on failures
      def build_failed?
        # TODO: set condition for failed build, when transaction checker supports it
        # @result = :failed if build_data.server.reload.state == :failed
        false
      end

      def build_succeded?
        @result = :success if build_data.server.reload.state == :on
      end

      def build_timeout?
        @result = :timeout if build_data.time_from_scheduled > MAX_BUILD_TIME
      end
    end
  end
end
