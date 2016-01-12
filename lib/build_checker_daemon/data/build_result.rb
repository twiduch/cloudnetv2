module BuildChecker
  module BuildCheckerData
    # Result of building test VM in OnApp
    class BuildResult
      include Mongoid::Document

      embedded_in :test_result
      belongs_to :server

      field :build_started,   type: Time
      field :build_ended,     type: Time

      # :success, :failed, :timeout
      field :build_result,    type: Symbol

      # :scheduling, :scheduled, :monitoring, :to_clean, :cleaning, :finished
      field :state,           type: Symbol
      field :delete_queued,   type: Boolean
      field :notified,        type: Boolean
      field :error

      def time_from_scheduled
        Time.now - build_started
      end

      def build_time
        return if build_started.nil? || build_ended.nil?
        (build_ended - build_started).round
      end
    end
  end
end
