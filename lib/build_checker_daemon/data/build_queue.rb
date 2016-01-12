module BuildChecker
  module BuildCheckerData
    # Messaging queues between threads
    class BuildQueue
      BATCH_SIZE = 100
      attr_accessor :working_size, :new_build, :batch_count,
                    :building_queue, :monitoring_queue, :cleaning_queue
      def initialize
        extend MonitorMixin
        @batch_count = 0
        @working_size = 0
        @new_build = new_cond
        @building_queue = Queue.new
        @monitoring_queue = Queue.new
        @cleaning_queue = Queue.new
      end

      def inc_size
        @batch_count = (@batch_count + 1) % BATCH_SIZE
        @working_size += 1
      end
    end
  end
end
