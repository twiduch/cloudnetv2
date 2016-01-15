require 'spec_helper'

describe BuildChecker::Builder::Scheduler do
  let(:queue) { BuildChecker::BuildCheckerData::BuildQueue.new }
  let(:scheduler_class) { BuildChecker::Builder::Scheduler }
  let!(:template) { Fabricate :template }
  subject { BuildChecker::Builder::Scheduler.new(queue) }
  let(:object) { subject.wrapped_object }

  before :example do
    Celluloid.shutdown
    Celluloid.boot
    allow(BuildChecker::Builder::BuilderWorker).to receive(:pool)
    allow_any_instance_of(BuildChecker::Builder::Scheduler).to receive(:run)
  end

  it 'initializes properly' do
    expect_any_instance_of(BuildChecker::Builder::Scheduler).to receive(:run)
    expect(BuildChecker::Builder::BuilderWorker).to receive(:pool)
    expect(subject.queue).to eq queue
  end

  it 'removes builds in :scheduling state' do
    tr = Fabricate(:checker_build_result, state: :monitoring).test_result
    Fabricate(:checker_build_result, test_result: tr, state: :scheduling)
    expect { object.remove_scheduling_builds }
      .to change { tr.reload.build_results.count }.from(2).to(1)
  end

  it 'waits for a signal to schedule build' do
    expect(object.queue).to receive(:synchronize).and_yield
    expect(object.queue.new_build).to receive(:wait_until)
    object.empty_slot?
  end

  it 'sets TestResult for template' do
    expect(template.reload.test_result).to be_nil
    object.next_template_for_test
    expect(template.reload.test_result).to be_a(BuildChecker::BuildCheckerData::TestResult)
  end

  it 'sets template_tested_id' do
    expect(System.get(:template_tested_id)).to be_empty
    object.next_template_for_test
    expect(System.get(:template_tested_id)).to eq template.id
  end

  it 'rolls templates' do
    template2 = Fabricate :template
    expect(object.next_template_for_test).to eq template
    expect(object.next_template_for_test).to eq template2
    expect(object.next_template_for_test).to eq template
  end

  # FIXME: Blocked as scheduler.rb:54 line must be removed
  xit 'waits for next test' do
    Timecop.freeze(Time.now)
    build_result = BuildChecker::BuildCheckerData::BuildResult.new(build_started: Time.now)
    expect(object).to receive(:sleep).with(BuildChecker::TIME_BETWEEN_TESTS)
    object.wait_for_test(build_result)
    Timecop.return
  end

  it 'schedules next build' do
    expect(object).to receive(:loop).and_yield
    expect(object.queue).to receive(:synchronize).twice.and_yield
    expect(object.queue.building_queue).to receive(:<<)
    expect(object.queue).to receive(:inc_size)
    allow_any_instance_of(scheduler_class).to receive(:run).and_call_original
    object.run
    expect(object.template.test_result.build_results.count).to eq 1
    expect(object.template.test_result.build_results.first.state).to eq :scheduling
    expect(object.template).to eq template
    expect(System.get(:template_tested_id)).to eq template.id
  end
end
