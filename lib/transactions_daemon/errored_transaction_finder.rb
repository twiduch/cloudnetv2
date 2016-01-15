module Transactions
  # If there is an error retrieving a batch of transactions then we need to find the specific erroring transaction
  # in order to report it and then poll it waiting for it to be fixed.
  class ErroredTransactionManager
    class << self
      include Cloudnet::Logger

      def run(starting_id)
        @starting_id = starting_id
        Transactions.update_state :finding_error
        find_erroring_transaction
      end

      def find_erroring_transaction
        increment_through_transactions
      rescue Faraday::Error::ResourceNotFound
        logger.error 'End of transactions reached without finding failing transaction.'
        Transactions.update_state Transactions::DEFAULT_TRANSACTION_STATE
      rescue Faraday::Error::ClientError => exception
        raise unless exception.response[:status] == 500
        errored_transaction_id = @id_to_try
        erroring_transaction errored_transaction_id
      end

      def increment_through_transactions
        @id_to_try = @starting_id + 1
        loop do
          OnappAPI.admin :get, "/transactions/#{@id_to_try}"
          @id_to_try += 1
        end
      end

      def erroring_transaction(id)
        logger.info "Errored transaction found: ID is #{id}"
        Email.transaction_error(id).deliver!
        wait_for_transaction_to_be_fixed id
      end

      def wait_for_transaction_to_be_fixed(id)
        Transactions.update_state :waiting_for_error_to_be_fixed
        loop do
          begin
            break if OnappAPI.admin :get, "/transactions/#{id}"
          rescue Faraday::Error::ClientError => exception
            raise unless exception.response[:status] == 500
            sleep 0.5
          end
        end
        Transactions.update_state Transactions::DEFAULT_TRANSACTION_STATE
      end
    end
  end
end
