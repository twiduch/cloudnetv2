require_relative 'transactions_consumer'

module Transactions
  # A daemon to constantly poll OnApp for new transactions. This enables the synchronisation of
  # OnApp resource (servers, disks, etc) states with cloud.net resource states.
  #
  # As described in the OnApp docs, "[Transactions] represents all the operations happening in your
  # cloud, such as VS provisioning, OS configuring, VS start up, operations with disks, and so on."
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
    # many new transactions, so no need to fetch too many.
    STANDARD_CONSUMPTION = 100

    def self.run
      Cloudnet.current_user = :syncdaemon
      Transactions::Sync.new.run
    end

    def initialize
      @consumer = Consumer.new
      @stasis = false
    end

    def run
      # This is a daemon, so loop forever
      loop { fetch_batch }
    end

    # If the previous loop is just doing the same as the current loop then the dameon is in stasis
    def set_stasis_state
      @stasis = @marker == @batch.last['id']
    end

    # Things to be done before fetching a batch of transactions
    def pre_fetch_chores
      @batch = []
      @marker = System.get(:transactions_marker).to_i
      # Note each attempt to sync so we can have some idea of whether the daemon is up and
      # running.
      System.set(:transactions_last_sync_attempt, Time.now)
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

    def find_page_to_start_consuming_from
      page = 1
      loop do
        logger.debug "Searching page #{page} (#{STANDARD_CONSUMPTION} per page) " \
          "of transactions log for marker ID #{@marker}"
        fetch_page page
        break if end_reached?
        page += 1
      end
      logger.debug "End of transactions found at page #{page}"
      page
    end

    def consume_from_page(starting_page)
      starting_page.downto(1) do |page|
        logger.debug "Fetching page #{page} (#{STANDARD_CONSUMPTION} per page) of transactions log"
        fetch_page page
        # The page containing the marker is likely to have some already-consumed transactions in it
        # so ignore them.
        @batch.select! { |i| i['id'] > @marker } if page == starting_page
        iterate
      end
    end

    # Figure out if we've reached as far as we can get in the logs. There are 2 situations in which
    # this could happen, see 1. and 2.
    def end_reached?
      # 1. If we reach where we last got to.
      return true if @batch.map { |t| t['id'].to_i }.include? @marker

      # 2. Curiously the OnApp API displays the oldest page when you ask for a non-existent page
      # number. So to check that we've reached the end we can see if the last page's first ID
      # is the same as the current page's first ID.
      @previous_batch_id ||= nil
      return true if @batch.last['id'] == @previous_batch_id
      @previous_batch_id = @batch.last['id']

      false
    end

    def fetch_page(page = 1, per_page = STANDARD_CONSUMPTION)
      params = { per_page: per_page, page: page }
      @batch = OnappAPI.admin :get, '/transactions', params
      fail 'No transactions found!' if @batch.length == 0
      @batch.map! { |t| t['transaction'] }
      # Reversing means that we always consume the oldest first
      @batch.reverse!
      # Are there new transactions to be consumed?
      set_stasis_state
    end

    def ignore_transaction?(transaction)
      [
        # We're currently only interested in VMs, but DNS will be consumed in the future too
        transaction['parent_type'] != 'VirtualMachine',

        # It would appear that there is some duplication of transactions when dealing with VMs
        # created on the Federation. When viewing the transaction logs for a VM in the Control Panel
        # GUI the 'ReceiveNotificationFromMarket' seem like noise and it's more intuitive to view the
        # various 'StartupVirtualServer', 'ConfigureOperatingSystem', etc. But for the purposes of
        # syncing the DB here, the 'ReceiveNotificationFromMarket' transactions offer advantages.
        # Firstly they are slightly more verbose, including the booting, building and locked states.
        # Secondly these transactions also contain the CPU, disk and network usage stats, so it
        # makes the code here a bit cleaner if we just completely ignore every other kind of
        # transaction.
        transaction['action'] != 'receive_notification_from_market',

        # There are some market events that don't have much interesting about them
        [
          'updated.resources.connect'
        ].include?(transaction['params']['event_type'])

      ].any?
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
