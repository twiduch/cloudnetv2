require_relative 'transactions_consumer'
require_relative 'sync_helpers'

# All things related to the synchronisation of state between OnApp and cloud.net using OnApp's transaction logs
module Transactions
  DEFAULT_TRANSACTION_STATE = :okay

  class << self
    def update_state(state)
      previous_state = System.get :transaction_daemon_state
      System.set :transaction_daemon_state, state
      Cloudnet.logger.info "Transaction daemon transitioned from '#{previous_state}' to '#{state}'"
    end
  end

  # A daemon to constantly poll OnApp for new transactions. This enables the synchronisation of
  # OnApp resource (servers, disks, etc) states with cloud.net resource states.
  #
  # As described in the OnApp docs, "[Transactions] represents all the operations happening in your
  # cloud, such as VS provisioning, OS configuring, VS start up, operations with disks, and so on."
  # See: https://docs.onapp.com/display/34API/Transactions
  class Sync
    include Cloudnet::Logger
    include SyncHelpers

    # The current batch of transactions being dealt with. Not guaranteed to be filtered
    attr_accessor :batch
    # The unfiltered batch, as returned immediately from Onapp
    attr_accessor :raw_batch
    # Whether the daemon has exhausted all the tranasactions it can for now
    attr_accessor :stasis

    # Page size of the first time the transactions log is ever consumed.
    FIRST_CONSUMPTION = 500
    # Page size normally. say if the daemon loops every second, there's likely not going to be
    # many new transactions, so no need to fetch too many.
    STANDARD_CONSUMPTION = 100

    def self.run
      Cloudnet.current_user = :syncdaemon
      Transactions.update_state Transactions::DEFAULT_TRANSACTION_STATE
      Transactions::Sync.new.run
    end

    def initialize
      @consumer = Consumer.new
      @stasis = false
    end

    def run
      logger.info 'Starting Transactions Daemon'
      # This is a daemon, so loop forever
      loop { fetch_batch }
    end

    # Retrieve a batch of transactions to consume
    def fetch_batch
      pre_fetch_chores
      if @marker == 0
        # This is the FIRST EVER consumption of the logs!
        # Gotta start somewhere so might as well go back as far as we sensibly can
        logger.debug "Fetching page 1 (#{FIRST_CONSUMPTION} per page) of transactions log"
        fetch_page 1, FIRST_CONSUMPTION
        iterate
      else
        page = find_page_to_start_consuming_from
        consume_from_page page
      end
    end

    # Sort and save any useful data from the transactions log. Typically we'll be finding out about
    # servers booting, updating, shutting down etc.
    def iterate
      @batch.each do |transaction|
        consume transaction unless ignore_transaction? transaction
        # Keep track of where we've got up to in the transactions log, so we don't re-consume.
        # Note that we take into account ignored transactions with the marker.
        System.set(:transactions_marker, transaction['id'])
      end
    end

    def consume(transaction)
      logger.debug "Consuming transaction #{transaction['id']}"
      @consumer.consume(transaction)
    rescue
      # This is bad news. We can't skip a transaction because there's the potential for the state
      # of a resource to become permanently out of sync.
      logger.error transaction.to_yaml
      raise
    end
  end
end
