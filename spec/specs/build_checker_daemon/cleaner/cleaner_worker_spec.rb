require 'spec_helper'

describe BuildChecker::Cleaner::CleanerWorker do
  let(:server) { Fabricate :server }
  let(:queue) { BuildChecker::BuildCheckerData::BuildQueue.new }
  let(:build_result) { Fabricate :checker_build_result, server: server }
  subject { BuildChecker::Cleaner::CleanerWorker.new(queue) }
  let(:object) { subject.wrapped_object }

  before :example do
    Celluloid.shutdown
    Celluloid.boot
    allow_any_instance_of(BuildChecker::Cleaner::CleanerWorker)
      .to receive(:async).and_return(double(perform: nil))
  end

  it 'initializes properly' do
    expect_any_instance_of(BuildChecker::Cleaner::CleanerWorker)
      .to receive(:async).and_return(double(perform: nil))
    expect(subject.queue).to eq queue
  end

  context 'gets data from the building queue' do
    before :example do
      allow(object).to receive(:error)
      expect(object).to receive(:loop).and_yield
      expect(object.queue.cleaning_queue).to receive(:pop).and_return(build_result)
    end

    it 'handles no local test server' do
      server.delete!
      build_result.reload
      object.perform
      expect(object.build_data.state).to eq :finished
      expect(object.build_data.error).to eq 'Local server data lost. Possible zombie at OnApp'
      expect(object.build_data.delete_queued).to be false
      expect(object.build_data.server_id).to be_nil
    end

    it 'handles existing local test server' do
      expect(object).to receive(:log_result)
      expect(BuildChecker::Cleaner::Cleaner).to receive(:destroy_test_vm)
      object.perform
      expect(object.build_data.state).to eq :cleaning
    end
  end

  context '#log_result' do
    before :example do
      allow(object).to receive_messages(error: nil, info: nil)
      object.instance_variable_set(:@build_data, build_result)
    end

    it 'updates data in DB on cleaner success' do
      object.log_result(server)
      expect(build_result.state).to eq :finished
      expect(object.build_data.delete_queued).to be true
      expect(build_result.server).to be_nil
      expect(build_result.error).to be_nil
    end

    it 'updates data in DB on cleaner error' do
      object.log_result('errors' => 'error message')
      expect(build_result.state).to eq :finished
      expect(object.build_data.delete_queued).to be false
      expect(build_result.server).to eq server
      expect(build_result.error).to eq 'errors' => 'error message'
    end
  end
end
