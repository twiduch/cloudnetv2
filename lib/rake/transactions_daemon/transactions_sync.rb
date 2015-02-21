require_relative 'transactions_consumer'

module Transactions
  # A daemon to constantly poll Onapp for new transactions. This enables the synchronisation of
  # Onapp resource (servers, disks, etc) states with cloud.net resource states.
  #
  # As described in the Onapp docs, "[Transactions] represents all the operations happening in your cloud,
  # such as VS provisioning, OS configuring, VS start up, operations with disks, and so on."
  # See: https://docs.onapp.com/display/34API/Transactions
  class Sync
    include Cloudnet::Logger

    class EndReached < StandardError; end

    # The current batch of transactions being dealt with. Not guaranteed to be filtered
    attr_accessor :batch
    # Whether the daemon has exhausted all the tranasactions it can for now
    attr_accessor :stasis

    # Page size of the first time the transactions log is ever consumed.
    FIRST_CONSUMPTION = 500
    # Page size normally. say if the daemon loops every second, there's likely not going to be
    # many new transactions, so need to fetch too many.
    STANDARD_CONSUMPTION = 100

    def self.run
      TransactionsSync.new.run
    end

    def initialize
      @api = OnappAPI.admin_connection
      @consumer = Consumer.new
      @stasis = false
    end

    def run
      # This is a daemon, so loop forever
      loop do
        fetch_batch
        iterate
      end
    end

    # If the previous loop is just doing the same as the current loop then the dameon is in stasis
    def set_stasis_state
      @stasis = @marker == @batch.last.id
    end

    # Retrieve a batch of transactions to consume
    def fetch_batch
      @batch = []
      @marker = System.get(:transactions_marker).to_i
      if @marker == 0
        # This is the FIRST EVER consumption of the logs!
        # Gotta start somewhere so might as well go back as far as we sensibly can
        fetch_page 1, FIRST_CONSUMPTION
      else
        find_most_recent
      end
    end

    # Go through all the paginated pages until we find the last transaction marked as consumed
    def find_most_recent
      page = 1
      # When we find the marker, we consume everything in that page that's new. But we rely on the
      # loop in initialise to carry on looking for any newer pages that we loop through here.
      loop do
        fetch_page page
        break if end_reached?
        @previous_batch_id = @batch.last.id
        page += 1
      end
      # Only keep those transactions with an ID greater than our stored marker
      @batch.select! { |i| i.id > @marker }
    end

    # Figure out if we've reached as far as we can get in the logs. There are 2 situations in which
    # this could happen, see 1. and 2.
    def end_reached?
      # 1. If we reach where we last got to.
      return true if @batch.map(&:id).include? @marker

      # 2. Curiously the Onapp API displays the oldest page when you ask for a non-existent page
      # number. So to check that we've reached the end we can see if the last page's first ID
      # is the same as the current page's first ID.
      @previous_batch_id ||= nil
      return true if @batch.last.id == @previous_batch_id

      false
    end

    def fetch_page(page = 1, per_page = STANDARD_CONSUMPTION)
      logger.debug "Searching page #{page} (#{per_page} per page) for unconsumed transactions"
      @batch = @api.transactions.get(params: { per_page: per_page, page: page })
      fail 'No transactions found!' if @batch.length == 0
      @batch.map!(&:transaction)
      # Reversing means that we always consume the oldest first
      @batch.reverse!
      # Are there new transactions to be consumed?
      set_stasis_state
    end

    def ignore_transaction?(transaction)
      # We're currently only interested in VMs, but DNS will be consumed in the future too
      return false if transaction.parent_type == 'VirtualMachine'

      # It would appear that there is some duplication of transactions when dealing with VMs
      # created on the Federation. When viewing the transaction logs for a VM in the Control Panel
      # GUI the 'ReceiveNotificationFromMarket' seem like noise and its more intuitive to view the
      # various 'StartupVirtualServer', 'ConfigureOperatingSystem', etc. But for the purposes of
      # syncing the DB here, the 'ReceiveNotificationFromMarket' transactions offer advantages.
      # Firstly they are slightly more verbose, including the booting, building and locked states.
      # Secondly these transactions also contain the CPU, disk and network usage stats, so it makes
      # the code here a bit cleaner if we just completely ignore every other kind of transaction.
      return false if transaction.action == 'receive_notification_from_market'

      true
    end

    # Sort and save any useful data from the transactions log. Typically we'll be finding out about
    # servers booting, updating, shutting down etc.
    def iterate
      @batch.each do |transaction|
        consume transaction unless ignore_transaction? transaction
        # Keep track of where we've got up to in the transactions log, so we don't re-consume.
        # Note that we take into account ignored transactions with the marker.
        System.set(:transactions_marker, transaction.id)
      end
    end

    def consume(transaction)
      @consumer.consume(transaction)
    rescue
      # This is bad news. We can't skip a transaction because there's the potential for the state
      # of a resource to become permanently out of sync.
      logger.error transaction.to_yaml
      raise
    end
  end
end
