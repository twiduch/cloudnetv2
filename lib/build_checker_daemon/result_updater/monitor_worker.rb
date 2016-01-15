module BuildChecker
  module ResultUpdater
    # Transaction daemon is responsible for updating local server collection
    # We assume server is built when VM changed status to :on
    # There is no monitoring of server removal
    class MonitorWorker
      include Celluloid
      include Celluloid::Internals::Logger
      include BuildCheckerData
      attr_reader :queue, :build_data

      def initialize(queue)
        @queue = queue
        async.perform
      end

      def perform
        loop do
          @build_data = queue.monitoring_queue.pop

          if build_data.server.present?
            start_monitoring
          else
            update_build(:failed, :finished, 'Local server data lost. Possible zombie at OnApp')
            build_data.update_attribute(:server_id, nil)
          end
          reduce_working_queue
        end
      end

      def start_monitoring
        debug "Monitoring #{build_data.server.inspect}"
        build_data.update_attribute(:state, :monitoring)
        log_result Monitor.monitor_test_vm(build_data)
      end

      def log_result(result)
        update_build(result)
        debug "Moving to cleaning queue: #{build_data.server.inspect}"
        queue.cleaning_queue << build_data
      end

      def update_build(result, state = :to_clean, error = nil)
        build_data.update_attributes(
          build_ended: Time.now,
          build_result: result,
          state: state,
          error: error
        )
      end

      def reduce_working_queue
        # Artificial time for destroy as we do not monitor destroys
        sleep 40 unless build_data.build_result == :failed
        queue.synchronize do
          queue.working_size -= 1
          debug "Finished monitoring. Queue running: #{queue.working_size}"
          queue.new_build.signal
        end
      end
    end
  end
end
