module Transactions
  # Each method deals with a particular type of transaction
  module ConsumerMethods
    # So far, all I can tell is that these only apply to completed VM destructions??
    def created__transaction
    end

    # Generally something to do with the components of a VM. Eg; provisioning disks, adding the OS
    # It's unclear as to how to use the :status field here. If a :status is not 'complete', can we
    # come back to the same transaction ID in the future? Would be useful to transition certain
    # events between something like 'pending', 'running' and 'complete'.
    def updated__transaction
      Transaction.create!(
        resource: :server,
        identifier: @transaction['identifier'],
        type: :event,
        details: @transaction['params']['event_data']['transaction']['action']
      )
    end

    # A build is scheduled but hasn't started yet
    def build_scheduled__virtual_machine
      @server.state = :building
      @server.built = false
      @server.locked = true
      @server.save!
    end

    # The VM is transitioning between states such as built, booted, etc
    # May provide duplicated info that is more readily provided by other transactions
    def updated_state__virtual_machine
      vm = @transaction['params']['event_data']['virtual_machine']
      @server.built = vm['built']
      if vm['booted']
        @server.state = :on
        @server.locked = false
      end
      @server.save!
    end

    def removed__virtual_machine
    end

    # Usage stats for CPU, disk and bandwidth
    # TODO: Consider using the :stat_time field to save as the created_at field
    def generated__statistics
      cleaned_hash = @transaction['params']['event_data'].deep_reject_key! 'virtual_machine_id'
      Transaction.create!(
        resource: :server,
        identifier: @transaction['identifier'],
        type: :stats,
        details: cleaned_hash.to_json
      )
    end
  end
end
