Fabricator :checker_test_result, from: 'BuildChecker::BuildCheckerData::TestResult' do
  template
end

Fabricator :checker_build_result, from: 'BuildChecker::BuildCheckerData::BuildResult' do
  test_result(fabricator: :checker_test_result)
  build_started Time.now
end
