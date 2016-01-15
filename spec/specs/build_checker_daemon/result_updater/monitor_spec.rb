require 'spec_helper'

describe BuildChecker::ResultUpdater::Monitor do
  let(:server) { Fabricate :server }
  let(:build_result) { Fabricate :checker_build_result, server: server }
  subject { BuildChecker::ResultUpdater::Monitor.new(build_result) }

  it 'creates new object and call monitor_test_vm' do
    monitor = double('Monitor')
    expect(BuildChecker::ResultUpdater::Monitor).to receive(:new).and_return(monitor)
    expect(monitor).to receive(:monitor_test_vm)
    BuildChecker::ResultUpdater::Monitor.monitor_test_vm(build_result)
  end

  it 'reports not ended build' do
    expect(subject.build_ended?).to be_falsey
  end

  it 'reports on successful build' do
    subject.build_data.server.update_attribute(:state, :on)
    expect(subject.build_ended?).to be_truthy
    expect(subject.result).to be :success
  end

  it 'reports on timeout build' do
    Timecop.freeze(build_result.build_started + BuildChecker::MAX_BUILD_TIME + 1.minute)
    expect(subject.build_ended?).to be_truthy
    expect(subject.result).to be :timeout
    Timecop.return
  end

  it 'reports result' do
    subject.build_data.server.update_attribute(:state, :on)
    expect(subject.monitor_test_vm).to be subject.result
  end
end
