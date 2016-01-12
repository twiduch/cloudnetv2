module BuildChecker
  module ResultUpdater
    # Schedule jobs for monitoring processes
    class Scheduler
      include Celluloid
      include Celluloid::Internals::Logger
      include BuildCheckerData
      attr_reader :queue
      POOL_SIZE = 5 # Needs DB connection

      def initialize(queue)
        @queue = queue
        ResultUpdater::MonitorWorker.pool(size: POOL_SIZE, args: [queue])
        monitor_lost_builds
      end

      # Makes sense only during boot phase
      # Builds that were monitored but abandoned due to actor crashes
      # or daemon termination
      def monitor_lost_builds
        lost_builds.each do |build_data|
          queue.synchronize do
            queue.monitoring_queue << build_data
            queue.working_size += 1
            debug "Lost build monitor fired. Size: #{queue.working_size}"
          end
        end
      end

      def lost_builds
        TestResult.where('build_results.state': :monitoring).map do |tr|
          tr.build_results.where(state: :monitoring).to_a
        end.flatten
      end
    end
  end
end
