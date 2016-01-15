require 'spec_helper'

describe BuildChecker::Orchestrator do
  it 'creates new object and call run' do
    orchestrator = double('Orchestrator')
    expect(BuildChecker::Orchestrator).to receive(:new).and_return(orchestrator)
    expect(orchestrator).to receive(:run)
    BuildChecker::Orchestrator.run
  end

  it 'raises error if no Datacentre synchornized' do
    expect { subject }.to raise_error RuntimeError
  end

  it 'starts supervised actors' do
    Fabricate :template
    expect(BuildChecker::Cleaner::Scheduler).to receive(:supervise)
    expect(BuildChecker::ResultUpdater::Scheduler).to receive(:supervise)
    expect(BuildChecker::Builder::Scheduler).to receive(:supervise)
    subject.run
  end
end
