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

  def simulate_server_error
    @tries += 1
    # Only simulate a failure on the first calls. This means that subsequent calls will kick into action the default
    # daemon mocking allowing it to reach stasis, break the loop and end the spec
    if @tries < 3
      fail Faraday::Error::ClientError.new 'Server Error', status: 500
    else
      false
    end
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

    # Record (or reuse) some HTTP requests
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
    @tries = 0
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

  it 'should respond to a 500 API response by finding the offending transaction' do
    ENV['CLOUDNET_SUPPORT_EMAIL'] = 'test@test.com'

    # The newest transaction is where we've gotten up to in the VCR cassette of real transactions
    newest_transaction = @first_batch.last
    newest_transaction_id = newest_transaction['id'].to_i
    System.set(:transactions_marker, newest_transaction_id)
    # When a batch fails ErroredTransactionManager will start incrementing looking for the culprit. For the sake of
    # argument the next transaction ID doesn't cause a 500
    next_transaction_id = newest_transaction_id + 1
    # But the one after that *will* cause a 500
    failing_transaction_id = newest_transaction_id + 2

    # The daemon goes about its normal business consuming transactions, but finds a page of transactions with an error
    # in it
    params = {
      per_page: @standard_consumption,
      page: 1
    }
    original = OnappAPI.method(:admin)
    allow(OnappAPI).to receive(:admin).with(:get, '/transactions', params) do |*args, &_block|
      simulate_server_error || original.call(*args)
    end
    # So it then tries to look for the individual transaction causing the error. We simulate a non-erroring transaction
    expect(OnappAPI).to receive(:admin).with(:get, "/transactions/#{next_transaction_id}")
    # And then it finds the problematic transaction
    allow(OnappAPI).to receive(:admin).with(:get, "/transactions/#{failing_transaction_id}") do
      simulate_server_error || true
    end

    # And reports the problem to support
    expect(Email).to receive(:transaction_error).with(failing_transaction_id).and_call_original

    run_daemon
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
