require 'spec_helper'

describe BuildChecker::BuildCheckerData::BuildResult do
  let(:build_result) { Fabricate :checker_build_result }

  it 'calculates time since build start' do
    Timecop.freeze(build_result.build_started + 1.hour)
    expect(build_result.time_from_scheduled).to eq 1.hour
    Timecop.return
  end

  it 'calculates build time' do
    build_result.build_ended = build_result.build_started + 10.minutes
    expect(build_result.build_time).to eq 10.minutes
  end
end
