module BuildChecker
  # Responsible for cleaning up data locally and at the OnApp after test
  module Cleaner
    # Schedule jobs for clean up
    class Scheduler
      include Celluloid
      include BuildCheckerData
      attr_reader :queue
      POOL_SIZE = 5 # Needs DB connection and API connection

      def initialize(queue)
        @queue = queue
        CleanerWorker.pool(size: POOL_SIZE, args: [queue])
        clean_left_builds
      end

      def clean_left_builds
        left_builds.each { |build_data| queue.cleaning_queue << build_data }
      end

      def left_builds
        left_test_results.map do |tr|
          tr.build_results.or({ state: :to_clean }, { state: :cleaning }).to_a
        end.flatten
      end

      def left_test_results
        TestResult.or({ 'build_results.state': :to_clean },
                      { 'build_results.state': :cleaning })
      end
    end
  end
end
