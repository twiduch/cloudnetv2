module Transactions
  # Just to try and keep Transaction::Sync small and sync, these are the general methods, leaving Transactions::Sync
  # more readable.
  module SyncHelpers
    # If the previous loop is just doing the same as the current loop then the dameon is in stasis
    def set_stasis_state
      if @batch.length == 0
        @stasis = false
      else
        @stasis = @marker == @batch.last['id']
      end
    end

    # Things to be done before fetching a batch of transactions
    def pre_fetch_chores
      @batch = []
      @marker = System.get(:transactions_marker).to_i
      # Note each attempt to sync so we can have some idea of whether the daemon is up and
      # running.
      System.set(:transactions_last_sync_attempt, Time.now)
    end

    def find_page_to_start_consuming_from
      page = 1
      loop do
        logger.debug "Searching page #{page} (#{Transactions::Sync::STANDARD_CONSUMPTION} per page) " \
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
        logger.debug "Fetching page #{page} (#{Transactions::Sync::STANDARD_CONSUMPTION} per page) of transactions log"
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

    def fetch_page(page = 1, per_page = Transactions::Sync::STANDARD_CONSUMPTION)
      page_api_request page, per_page
      @batch.map! { |t| t['transaction'] }
      # Reversing means that we always consume the oldest first
      @batch.reverse!
      # Are there new transactions to be consumed?
      set_stasis_state
    end

    def page_api_request(page, per_page)
      params = { page: page, per_page: per_page }
      @batch = OnappAPI.admin :get, '/transactions', params
      fail 'No transactions found!' if @batch.length == 0
    rescue Faraday::Error::ClientError => exception
      raise unless exception.response[:status] == 500
      logger.error "#{ENV['ONAPP_URI']}/transactions.json?per_page=#{per_page}&page=#{page} triggered a 500 error"
      # Because the batch contained multiple transactions, we start looking for the culprit from the last
      # recorded successful transaction defined by @marker.
      ErroredTransactionManager.run @marker
      retry
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
  end
end
