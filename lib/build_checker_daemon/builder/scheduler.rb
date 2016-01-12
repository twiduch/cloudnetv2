module BuildChecker
  module Builder
    # Assumes Templates synchronized
    class Scheduler
      include Celluloid
      include Celluloid::Internals::Logger
      include BuildCheckerData
      attr_reader :template, :queue
      POOL_SIZE = 5 # Needs DB connection and API connection

      def initialize(queue)
        @queue = queue
        @templates_count = Template.count
        BuilderWorker.pool(size: POOL_SIZE, args:[queue])
        run
      end

      def run
        remove_scheduling_builds # FIXME: What to do with :scheduled ?
        loop { schedule_build if empty_slot? }
      end

      # Builds are scheduled in the same order. 
      # Time to wait is longest for next_template_for_test
      def schedule_build
        debug "scheduling new build"
        @template = next_template_for_test
        next_build if time_for_test?
      end

      def next_build
        build_data = prepare_build_data
        queue.synchronize do
          queue.building_queue << build_data
          queue.inc_size
          debug "increasing builder #{queue.working_size}"
        end 
      end
      
      def prepare_build_data
        build_data = BuildResult.new(state: :scheduling, build_started: Time.now)
        template.test_result.build_results << build_data
        build_data
      end

      def time_for_test?
        last_build = template.test_result.build_results.
                     order_by(build_started: 'desc').limit(1).first
        last_build ? wait_for_test(last_build) : true
      end

      def wait_for_test(build)
        passed = build.time_from_scheduled
        terminate if passed < TIME_BETWEEN_TESTS # TODO: remove !!
        sleep(TIME_BETWEEN_TESTS - passed) if passed < TIME_BETWEEN_TESTS
        true
      end

      def empty_slot?
        queue.synchronize do
          queue.new_build.wait_until {queue.working_size < CONCURRENT_BUILDS}
          debug "Builders running: #{queue.working_size}"
        end
        true
      end

      def next_template_for_test
        tmpl = next_template
        tmpl.test_result = TestResult.new unless tmpl.test_result
        System.set(:template_tested_id, tmpl.id)
        tmpl
      end

      def next_template
        tmpl = Template.where(:id.gt => tested_template_id).order_by(id: 'asc').limit(1).first
        tmpl ? tmpl : initial_template
      end
    
      def tested_template_id
        System.get(:template_tested_id)
      end

      def initial_template
        Template.order_by(id: 'asc').limit(1).first
      end

      # Only for boot phase
      def remove_scheduling_builds
        TestResult.where('build_results.state': :scheduling).each do |tr|
          tr.build_results.where(state: :scheduling).delete_all 
        end
      end
    end
  end
end