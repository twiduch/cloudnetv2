require 'spec_helper'

describe Transactions do
  # Run the daemon. Need to run in a thread because it loops forever and killing the thread is the
  # best way of stopping it.
  def run_daemon
    @syncer = Transactions::Sync.new
    @thread = Thread.new do
      @syncer.run
    end
    @thread.abort_on_exception = true
    microsleep until @syncer.stasis
  end

  def microsleep
    sleep 0.05
  end

  # Just to make sure we have already recorded all the HTTP requests we need. Otherwise certain
  # tests duplicate the recording of HTTP requests, because VCR doesn't replay a request until it
  # has been recorded.
  before :all do
    # Try to reduce the size of the VCR cassette:
    # The size of the page we'd like to consume for the first ever query of the live transactions log.
    @first_consumption = 30
    # Page size for normal queries
    @standard_consumption = 5

    # Record some HTTP requests
    syncer = Transactions::Sync.new
    VCR.use_cassette 'transactions_log' do
      syncer.fetch_page 1, @first_consumption
      @first_batch = syncer.batch
      @first_batch.reject! { |i| syncer.ignore_transaction? i }
      7.times do |page|
        syncer.fetch_page page + 1, @standard_consumption
      end
    end

    # Because we can't easily dictate what the Onapp API's logs are we just have to work with
    # whatever VCR records at the time. The only condition is that there's more transactions than
    # the @standard_consumption per page. Testing the tests!
    if @first_batch.length <= @standard_consumption
      fail 'No transactions found, tests need at least a page of transactions'
    end

    # For the sake of testing, assume that oldest transaction from @first_batch is the oldest transaction on the CP
    oldest_transaction = @first_batch.first
    System.set(:transactions_marker, oldest_transaction['id'])
  end

  around do |example|
    VCR.use_cassette 'transactions_log' do
      # When dealing with a daemon, it's best to have a safety measure to break out of the loop
      Timeout.timeout(5) do
        example.run
      end
    end
  end

  before :each do
    stub_const('Transactions::Sync::FIRST_CONSUMPTION', @first_consumption)
    stub_const('Transactions::Sync::STANDARD_CONSUMPTION', @standard_consumption)
    @consumer = instance_double Transactions::Consumer
    allow(Transactions::Consumer).to receive(:new).and_return(@consumer)
    allow(@consumer).to receive(:consume)
  end

  after :each do
    @thread.kill if @thread
  end

  it 'should make a note of the latest consumed transaction' do
    run_daemon
    latest_id = @first_batch.last['id']
    latest_marker = System.get(:transactions_marker)
    expect(latest_marker).to eq latest_id
  end

  it 'should loop, watching for new transactions, then consume if a new transaction appears' do
    run_daemon
    expect(@syncer.stasis)

    # Simulate a new transaction by reverting the marker to an older one
    newest_transaction = @first_batch.last
    second_newest_transaction = @first_batch[-2]
    expect(@consumer).to receive(:consume).exactly(:once).with(newest_transaction)
    System.set(:transactions_marker, second_newest_transaction['id'])
    microsleep until System.get(:transactions_marker) == newest_transaction['id']
  end

  it 'should dig through multiple pages to find the oldest consumed transaction' do
    run_daemon
    expect(@syncer.stasis)

    # Simulate new transactions by reverting the marker to an older one
    newest_transaction = @first_batch.last
    back = @standard_consumption * 2 # at least 2 pages back
    transaction_in_deep_page = @first_batch[-back]
    # `count` is 1 less than `back` because ruby's array[-1] is effectively 1-indexed, not 0-indexed
    count = back - 1
    expect(@consumer).to receive(:consume).exactly(count).times
    System.set(:transactions_marker, transaction_in_deep_page['id'])
    microsleep until System.get(:transactions_marker) == newest_transaction['id']
  end

  describe Transactions::Consumer do
    it 'should be called the same number of times as there are valid transactions' do
      calls = @first_batch.length
      expect(@consumer).to receive(:consume).exactly(calls).times
      run_daemon
    end

    it 'should call a specific consumer method' do
      # Reset the mock so it acts as normal
      allow(Transactions::Consumer).to receive(:new).and_call_original
      event = Transactions::Consumer.event_to_method @first_batch.last
      # Create the associated server, otherwise the daemon will ignore the transaction
      Fabricate :server, onapp_identifier: @first_batch.last['identifier']
      expect_any_instance_of(Transactions::Consumer).to receive(event[:method]).at_least(:once)
      run_daemon
    end

    it 'should stop the daemon if even a single consumption fails' do
      allow(@consumer).to receive(:consume).and_raise StandardError
      expect { run_daemon }.to raise_exception StandardError
    end
  end
end
