module BuildChecker
  module Cleaner
    # Responsible for destroying test VM in Onapp and local DB
    # Destroy in OnApp is not monitored now. We assume so, after request has been accepted
    # Such monitoring should be handled by transaction daemon
    class Cleaner
      attr_reader :server, :result

      def self.destroy_test_vm(server)
        new(server).destroy_test_vm
      end

      def initialize(server)
        @server = server
      end

      def destroy_test_vm
        @result = destroy_onapp_vm
        onapp_vm_destroyed? ? remove_local_data : result
      end

      def remove_local_data
        server.transactions.delete_all
        server.history_tracks.delete_all
        server.delete!
        server # TODO: Handle failed delete!
      end

      def onapp_vm_destroyed?
        case result
        when { 'errors' => ['VirtualMachine not found'] } then true
        when nil then true # TODO: Monitor if VM really destroyed
        else false
        end
      end

      # Send delete request to onapp
      def destroy_onapp_vm
        OnappAPI.admin(:delete, "virtual_machines/#{server.onapp_identifier}")
      rescue => e
        { 'errors' => e.message }
      end
    end
  end
end
