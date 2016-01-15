require 'spec_helper'

describe BuildChecker::Cleaner::Scheduler do
  let(:queue) { BuildChecker::BuildCheckerData::BuildQueue.new }
  subject { BuildChecker::Cleaner::Scheduler.new(queue) }
  let(:object) { subject.wrapped_object }

  before :example do
    Celluloid.shutdown
    Celluloid.boot
    allow(BuildChecker::Cleaner::CleanerWorker).to receive(:pool)
  end

  it 'initializes properly' do
    expect(BuildChecker::Cleaner::CleanerWorker).to receive(:pool)
    expect(subject.queue).to eq queue
  end

  it 'moves left builds to cleaning queue' do
    tr1 = Fabricate(:checker_build_result, state: :to_clean).test_result
    Fabricate(:checker_build_result, test_result: tr1, state: :to_clean)
    Fabricate(:checker_build_result, test_result: tr1, state: :monitoring)
    tr2 = Fabricate(:checker_build_result, state: :monitoring).test_result
    Fabricate(:checker_build_result, test_result: tr2, state: :cleaning)
    Fabricate(:checker_build_result, test_result: tr2, state: :monitoring)

    expect { object }.to change(queue.cleaning_queue, :size).from(0).to(3)
  end
end
