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

    # Convert something like 'updated.transaction.connect' to 'updated__transaction'
    def self.event_to_method(transaction)
      raw = transaction.params.event_type
      {
        raw: raw,
        method: raw.gsub('.connect', '').gsub('.', '__')
      }
    end

    def resource_present_in_cloudnet?
      case @transaction.parent_type
      when 'VirtualMachine'
        @server = Server.find(@transaction.identifier)
      end
    rescue Mongoid::Errors::DocumentNotFound
      false
    end

    def consume(transaction)
      @transaction = transaction
      event = self.class.event_to_method(@transaction)
      return unless resource_present_in_cloudnet?
      call_event_as_method(event)
    end

    def call_event_as_method(event)
      if known_transaction? event[:method]
        @debug = [event[:raw], @transaction.identifier, @transaction.status]
        send event[:method]
        # The consumer methods can add to @debug
        logger.debug @debug
      else
        logger.warning "Unknown transaction type: #{event[:raw]}"
      end
    end
  end
end
