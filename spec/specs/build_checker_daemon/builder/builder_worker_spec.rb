require 'spec_helper'

describe BuildChecker::Builder::BuilderWorker do
  let(:queue) { BuildChecker::BuildCheckerData::BuildQueue.new }
  let(:build_result) { Fabricate :checker_build_result }
  subject { BuildChecker::Builder::BuilderWorker.new(queue) }
  let(:object) { subject.wrapped_object }

  before :example do
    Celluloid.shutdown
    Celluloid.boot
    allow_any_instance_of(BuildChecker::Builder::BuilderWorker)
      .to receive(:async).and_return(double(perform: nil))
  end

  it 'initializes properly' do
    expect_any_instance_of(BuildChecker::Builder::BuilderWorker)
      .to receive(:async).and_return(double(perform: nil))
    expect(subject.queue).to eq queue
  end

  it 'gets data from the building queue' do
    expect(object).to receive(:loop).and_yield
    expect(object.queue.building_queue).to receive(:pop).and_return(build_result)
    expect(object).to receive(:log_result)
    allow(object).to receive(:sleep)
    expect(BuildChecker::Builder::Builder).to receive(:build_test_vm)
    object.perform
  end

  describe '#log_result' do
    before :example do
      object.instance_variable_set(:@build_data, build_result)
      object.instance_variable_set(:@template, build_result.test_result.template)
    end

    context 'on builder success' do
      let(:server) { Fabricate :server }

      it 'updates data in DB' do
        object.log_result(server)
        expect(build_result.build_started).to be_a(Time)
        expect(build_result.build_ended).to be_nil
        expect(build_result.build_result).to be_nil
        expect(build_result.state).to eq :scheduled
        expect(build_result.server).to be server
      end

      it 'fills monitoring queue' do
        expect { object.log_result(server) }.to change(object.queue.monitoring_queue, :size).from(0).to(1)
      end

      it 'does not signal new built' do
        expect(object.queue.new_build).not_to receive(:signal)
        expect { object.log_result(server) }.not_to change(object.queue, :working_size)
      end
    end

    context 'on builder error' do
      before :example do
        allow(object).to receive(:error)
      end

      it 'updates data in DB' do
        object.log_result('error message')
        expect(build_result.build_started).to be_a(Time)
        expect(build_result.build_ended).to be_a(Time)
        expect(build_result.build_result).to eq :failed
        expect(build_result.state).to eq :finished
        expect(build_result.error).to eq 'error message'
      end

      it 'reduces queue size and signal free building slot' do
        expect(object.queue).to receive(:synchronize).and_yield
        expect(object.queue.new_build).to receive(:signal)
        object.queue.inc_size
        expect { object.log_result('error message') }.to change(object.queue, :working_size).from(1).to(0)
      end
    end
  end
end
