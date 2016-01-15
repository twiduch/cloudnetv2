# Builds test VMs using all accessible templates
module BuildChecker
  CONCURRENT_BUILDS = 2

  # Assumption: TIME_BETWEEN_TESTS > MAX_BUILD_TIME
  TIME_BETWEEN_TESTS = 14.days # Minimum time between tests for the same template
  MAX_BUILD_TIME = 1.hour # Build time of VM at OnApp

  # Only ONE Orchestrator process must be running.
  class Orchestrator
    def self.run
      Cloudnet.current_user = :buildchecker
      Celluloid.logger = Cloudnet.logger
      BuildChecker::Orchestrator.new.run
    end

    def initialize
      return if datacentres_synchronized?
      fail 'Use: rake update_federation_resources to get available datacentres'
    end

    def run
      Cleaner::Scheduler.supervise args: [queue]
      ResultUpdater::Scheduler.supervise args: [queue]
      Builder::Scheduler.supervise args: [queue]
    end

    def queue
      @queue ||= BuildCheckerData::BuildQueue.new
    end

    def datacentres_synchronized?
      Datacentre.count > 0 && Template.count > 0
    end
  end
end
