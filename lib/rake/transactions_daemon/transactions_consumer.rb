require_relative 'consumer_methods'

module Transactions
  # Passes off consumption of a particular transaction type to a dedicated consumer
  class Consumer
    include Cloudnet::Logger
    include ConsumerMethods

    def known_transactions
      ConsumerMethods.instance_methods.map(&:to_s)
    end

    def known_transaction?(action)
      known_transactions.include? action
    end

    def consume(transaction)
      @transaction = transaction
      # Convert something like 'updated.transaction.connect' to 'updated__transaction'
      event_type_raw = @transaction.params.event_type
      event_type = event_type_raw.gsub('.connect', '').gsub('.', '__')
      if known_transaction? event_type
        @debug = [event_type_raw, @transaction.identifier, @transaction.status]
        send event_type
        # The consumer methods can add to @debug
        logger.debug @debug
      else
        logger.info "Unknown transaction type: #{event_type_raw}"
      end
    end
  end
end
