require 'spec_helper'

describe BuildChecker::ResultUpdater::Scheduler do
  let(:queue) { BuildChecker::BuildCheckerData::BuildQueue.new }
  subject { BuildChecker::ResultUpdater::Scheduler.new(queue) }
  let(:object) { subject.wrapped_object }

  before :example do
    Celluloid.shutdown
    Celluloid.boot
    allow(BuildChecker::ResultUpdater::MonitorWorker).to receive(:pool)
  end

  it 'initializes properly' do
    expect(BuildChecker::ResultUpdater::MonitorWorker).to receive(:pool)
    expect(subject.queue).to eq queue
  end

  def fabricate_build_results
    tr1 = Fabricate(:checker_build_result, state: :to_clean).test_result
    Fabricate(:checker_build_result, test_result: tr1, state: :to_clean)
    Fabricate(:checker_build_result, test_result: tr1, state: :monitoring)
    tr2 = Fabricate(:checker_build_result, state: :monitoring).test_result
    Fabricate(:checker_build_result, test_result: tr2, state: :cleaning)
    Fabricate(:checker_build_result, test_result: tr2, state: :monitoring)
  end

  it 'moves abandoned builds to monitoring queue' do
    fabricate_build_results
    expect { object }.to change(queue.monitoring_queue, :size).from(0).to(3)
  end

  it 'increases queue working_size' do
    expect(object.queue).to receive(:synchronize).exactly(3).times.and_yield
    fabricate_build_results
    expect { object.monitor_lost_builds }
      .to change(object.queue, :working_size).by(3)
  end
end
