module BuildChecker
  module Builder
    # Worker for VM build and DB updates
    class BuilderWorker
      include Celluloid
      include Celluloid::Internals::Logger
      include BuildCheckerData
      attr_reader :template, :build_data, :queue

      def initialize(queue)
        @queue = queue
        async.perform
      end

      def perform
        loop do
          @build_data = queue.building_queue.pop
          @template = @build_data.test_result.template
          sleep rand(10)
          log_result Builder.build_test_vm(template)
        end
      end

      def log_result(result)
        if result.is_a? Server
          move_to_monitoring_queue(result)
        else
          mark_error(result)
          free_building_slot
        end
      end

      def move_to_monitoring_queue(result)
        build_data.update_attributes(
          server: result,
          state: :scheduled
        )
        debug "Moving to monitoring queue. Still running: #{queue.working_size}"
        queue.monitoring_queue << build_data
      end

      def mark_error(result)
        error "Test VM for template #{template.id} raised ERROR"
        build_data.update_attributes(
          build_result: :failed,
          state: :finished,
          error: result,
          build_ended: Time.now
        )
      end

      def free_building_slot
        queue.synchronize do
          queue.working_size -= 1
          debug "Removing running: #{queue.working_size}"
          queue.new_build.signal
        end
      end
    end
  end
end
