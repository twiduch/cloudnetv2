module BuildChecker
  module BuildCheckerData
    # Storing all tests performed for given template
    class TestResult
      include Mongoid::Document
      include Mongoid::Timestamps
      store_in collection: 'build_checker_results'

      belongs_to :template
      embeds_many :build_results
    end
  end
end
