require 'spec_helper'

describe Transactions::ConsumerMethods do
  def search_for_transaction_type
    page = 1
    matches = []
    loop do
      matches = find_match page
      break if matches.length > 1
      page += 1
    end
    transaction_to_fixture(matches.first)
  end

  def find_match(page)
    params = { per_page: 100, page: page }
    batch = OnappAPI.admin :get, '/transactions', params
    batch.map! { |b| b['transaction'] }
    batch.select { |t| t['params']['event_type'] == @type }
  end

  def transaction_to_fixture(transaction)
    yaml = transaction.to_yaml
    File.write(transaction_fixture_path, yaml)
  end

  def transaction_fixture_path
    "#{Cloudnet.root}/spec/fixtures/transactions/#{@type}.yml"
  end

  def transaction_fixture
    path = transaction_fixture_path
    return false unless File.exist? path
    YAML.load(File.read(path))
  end

  def load_or_create_transaction_fixture
    VCR.turned_off do
      @transaction = transaction_fixture
      # If we don't already have a cassette of this transaction query the OnApp CP to find one
      unless @transaction
        WebMock.allow_net_connect!
        search_for_transaction_type
        WebMock.disable_net_connect!
        @transaction = transaction_fixture
      end
    end
  end

  # Shorthand
  def consume
    Transactions::Consumer.new.consume @transaction
    @server.reload
  end

  before :each do |example|
    # Fancy technique: we take the transaction name from the spec's description.
    # Eg; 'should consume <updated.transaction.connect>' gives 'updated.transaction.connect'
    @type = example.metadata[:description].scan(/<([^>]*)>/).first.first
    # Now we can fetch an example fixture for that transaction
    load_or_create_transaction_fixture
    # Just assume that we already have the resource in our DB
    @server = Fabricate :server, onapp_identifier: @transaction['identifier']
  end

  it 'should consume <updated.transaction.connect>' do
    consume
    persisted = Transaction.find_by(identifier: @transaction['identifier'])
    expect(persisted.details).to eq @transaction['params']['event_data']['transaction']['action']
  end

  it 'should consume <updated_state.virtual_machine.connect>' do
    consume
    expect(@server.built).to eq @transaction['params']['event_data']['virtual_machine']['built']
  end

  it 'should consume <build_scheduled.virtual_machine.connect>' do
    consume
    expect(@server.state).to eq :building
    expect(@server.ip_address).not_to be_empty
  end

  it 'should consume <generated.statistics.connect>' do
    consume
    persisted = Transaction.find_by(identifier: @transaction['identifier'])
    json = JSON.parse persisted.details
    expect(json.keys).to eq %w(disk_hourly_stats net_hourly_stats cpu_hourly_stats)
  end

  it 'should consume <created.transaction.connect>' do
    consume
  end
end
