module BuildChecker
  # A daemon to verify if VM can be built in location
  class Orchestrator
    include Cloudnet::Logger

    # BUILD_EVERY Makes sense to be significantly more than Monitor::MAX_TIME_FOR_BUILT
    BUILD_EVERY = 6.hours
    CHECK_EVERY = 1.minute

    def self.run
      BuildChecker::Orchestrator.new.run
    end

    def initialize
      return if datacentres_synchronized? && last_built_set
      fail 'Use: rake update_federation_resources to get available datacentres'
    end

    def run
      logger.info 'Build Checker started'
      # This is a daemon, so loop forever
      loop do
        verify_test_vm(test_vm) do |result|
          result.success # Generating logs
          result.error { Notifier.test_vm_not_built }
        end
        clean_up
      end
    end

    def test_vm
      Builder.build_test_vm if time_for_vm_build?
    end

    def time_for_vm_build?
      sleep CHECK_EVERY until ((Time.now - last_built_time) / BUILD_EVERY).floor > 0
      true
    end

    def verify_test_vm(server)
      yield Monitor.check(server)
    end

    def last_built_time
      System.get(:last_test_vm_build)
    end

    # Send notification if not all test vms destroyed
    def clean_up
      Notifier.test_vm_left if Builder.destroy_test_vms > 0
    end

    def datacentres_synchronized?
      Datacentre.count > 0 && Template.count > 0
    end

    # First time run - no property set
    def last_built_set
      System.set(:last_test_vm_build, Time.now - BUILD_EVERY) if last_built_time == ''
      true
    end
  end
end
