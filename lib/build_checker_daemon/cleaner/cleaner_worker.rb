module BuildChecker
  module Cleaner
    # TODO:
    # Transaction daemon should update local server entry when OnApp VM destroyed
    # For now on we assume deleted just after succesful call to OnApp
    class CleanerWorker
      include Celluloid
      include Celluloid::Internals::Logger
      include BuildCheckerData
      attr_reader :build_data, :queue

      def initialize(queue)
        @queue = queue
        async.perform
      end

      def perform
        loop do
          @build_data = queue.cleaning_queue.pop

          if build_data.server.present?
            debug "Cleaning #{build_data.server.inspect}"
            build_data.update_attribute(:state, :cleaning)
            log_result Cleaner.destroy_test_vm(build_data.server)
          else
            error "Server Lost #{build_data.inspect}"
            finish_build(false, "Local server data lost. Possible zombie at OnApp")
            clear_server_link
          end
        end
      end

      def log_result(result)
        if result.is_a? Server
          finish_build
          clear_server_link
          info "Test VM destroyed properly: #{result.onapp_identifier} "
        else
          finish_build(false, result)
          error "Test VM #{build_data.server.inspect} raised ERROR when trying to delete in OnApp"
        end
      end

      def finish_build(delete_queued = true, error = nil)
        build_data.update_attributes(
          state: :finished,
          delete_queued: delete_queued,
          error: build_data.error || error
        )
      end

      def clear_server_link
        build_data.update_attribute(:server_id, nil)
      end
    end
  end
end
