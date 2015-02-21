module Transactions
  # Each method deals with a particular type of transaction
  module ConsumerMethods
    # Generally something to do with the components of a VM. Eg; provisioning disks, adding the OS
    def updated__transaction
      @debug << @transaction.params.event_data.transaction.action
      @debug << @transaction.params.event_data.transaction.status
    end

    # The VM is transitioning between states such as built, booted, etc
    def updated_state__virtual_machine
    end

    # A build is scheduled but hasn't started yet
    def build_scheduled__virtual_machine
    end

    # Usage stats for CPU, disk and bandwidth
    def generated__statistics
      nil
    end

    def created__transaction
    end

    def removed__virtual_machine
    end
  end
end
