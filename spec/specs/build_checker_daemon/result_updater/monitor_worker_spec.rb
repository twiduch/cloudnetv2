require 'spec_helper'

describe BuildChecker::ResultUpdater::MonitorWorker do
  let(:server) { Fabricate :server }
  let(:queue) { BuildChecker::BuildCheckerData::BuildQueue.new }
  let(:build_result) { Fabricate :checker_build_result, server: server }
  subject { BuildChecker::ResultUpdater::MonitorWorker.new(queue) }
  let(:object) { subject.wrapped_object }

  before :example do
    Celluloid.shutdown
    Celluloid.boot
    allow_any_instance_of(BuildChecker::ResultUpdater::MonitorWorker)
      .to receive(:async).and_return(double(perform: nil))
  end

  it 'initializes properly' do
    expect_any_instance_of(BuildChecker::ResultUpdater::MonitorWorker)
      .to receive(:async).and_return(double(perform: nil))
    expect(subject.queue).to eq queue
  end

  context 'gets data from the monitoring queue' do
    before :example do
      allow(object).to receive(:sleep)
      expect(object).to receive(:loop).and_yield
      expect(object.queue.monitoring_queue).to receive(:pop).and_return(build_result)
    end

    it 'handles no local test server' do
      server.delete!
      build_result.reload
      object.perform
      expect(object.build_data.state).to eq :finished
      expect(object.build_data.build_result).to eq :failed
      expect(object.build_data.error).to eq 'Local server data lost. Possible zombie at OnApp'
      expect(object.build_data.delete_queued).to be_nil
      expect(object.build_data.server_id).to be_nil
      expect(object.build_data.build_ended).to be_a(Time)
    end

    it 'handles existing local test server' do
      expect(object).to receive(:log_result)
      expect(BuildChecker::ResultUpdater::Monitor).to receive(:monitor_test_vm)
      object.perform
      expect(object.build_data.state).to eq :monitoring
    end

    it 'reduces working_queue and signals empty slot' do
      allow(object).to receive(:log_result)
      allow(BuildChecker::ResultUpdater::Monitor).to receive(:monitor_test_vm)
      expect(object.queue).to receive(:synchronize).and_yield
      expect(object.queue.new_build).to receive(:signal)
      expect { object.perform }.to change(object.queue, :working_size).by(-1)
    end
  end

  it 'logs result and move to cleaning queue' do
    object.instance_variable_set(:@build_data, build_result)
    object.log_result(:result)
    expect(object.build_data.build_result).to eq :result
    expect(object.build_data.state).to eq :to_clean
    expect(object.build_data.server_id).to be_a(BSON::ObjectId)
    expect(object.build_data.build_ended).to be_a(Time)
  end
end
