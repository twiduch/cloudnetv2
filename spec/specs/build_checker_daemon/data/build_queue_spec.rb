require 'spec_helper'

describe BuildChecker::BuildCheckerData::BuildQueue do
  let(:build_queue) { BuildChecker::BuildCheckerData::BuildQueue.new }

  it 'sets up queues' do
    expect(build_queue.building_queue).to be_a(Queue)
    expect(build_queue.monitoring_queue).to be_a(Queue)
    expect(build_queue.cleaning_queue).to be_a(Queue)
    expect(build_queue.new_build).to be_a(MonitorMixin::ConditionVariable)
  end

  it 'increments working size' do
    expect { build_queue.inc_size }.to change(build_queue, :working_size).from(0).to(1)
  end
end
