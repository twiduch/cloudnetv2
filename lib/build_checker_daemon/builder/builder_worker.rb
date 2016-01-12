require 'pry'
module BuildChecker
  module Builder
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
          build_data.update_attributes(
            server: result,
            state: :scheduled
          )
          debug "Moving to monitoring queue. Still running: #{queue.working_size}"
          queue.monitoring_queue << build_data
        else
          error "Test VM for template #{template.id} raised ERROR"
          build_data.update_attributes(
            build_result: :failed,
            state: :finished,
            error: result,
            build_ended: Time.now
          )
          queue.synchronize do
            queue.working_size -= 1
            debug "Removing running: #{queue.working_size}"
            queue.new_build.signal
          end
        end
      end
    end
  end
end