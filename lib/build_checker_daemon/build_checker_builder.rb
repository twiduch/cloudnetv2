module BuildChecker
  # Responsible for building and destroying test VM in Onapp and local DB
  # TODO: Destroy in OnApp is not monitored now. We assume so after request has been accepted
  class Builder
    include Cloudnet::Logger
    HOSTNAME = 'build-checker'

    class << self
      def build_test_vm
        note_new_built
        new.build_test_vm
      end

      def destroy_test_vms
        new.destroy_test_vms
      end

      def note_new_built
        System.set(:last_test_vm_build, Time.now)
      end
    end

    def build_test_vm
      return ['No linux template available'] if template.nil?
      return new_onapp_vm['errors'] if new_onapp_vm['errors'].present?
      save_local_vm
    end

    # Removing all test VMs
    # Returns number of test VMs that were NOT destroyed (normally should be 0)
    def destroy_test_vms
      test_vms.each do |vm|
        remove_local_data(vm) if onapp_vm_destroyed?(vm)
      end.count
    end

    def remove_local_data(vm)
      vm.transactions.delete_all
      vm.delete!
      logger.info "Test VM #{vm.onapp_identifier} destroyed properly"
    end

    def onapp_vm_destroyed?(vm)
      case destroy_onapp_vm(vm)
      when { 'errors' => ['VirtualMachine not found'] } then true
      when nil then true # TODO: Monitor if VM really destroyed
      else
        logger.error 'OnApp Test VM not destroyed'
        false
      end
    end

    # Send delete request to onapp
    def destroy_onapp_vm(vm)
      OnappAPI.admin(:delete, "virtual_machines/#{vm.onapp_identifier}")
    rescue => e
      { 'errors' => e.message }
    end

    # All VMs used for tests
    def test_vms
      Server.where(user: nil, hostname: HOSTNAME)
    end

    def save_local_vm
      new_local_vm.onapp_identifier = new_onapp_vm['virtual_machine']['identifier']
      new_local_vm.save!
      logger.info "Test VM #{new_local_vm.onapp_identifier} scheduled for build"
      new_local_vm
    end

    # Local representation of test vm
    # Has no user defined
    def new_local_vm
      @local_vm ||= Server.new(local_server_params)
    end

    # Creating new test vm in onapp
    def new_onapp_vm
      @onapp_vm ||=
        begin
          OnappAPI.admin(:post, 'virtual_machines', onapp_server_params)
        rescue => e
          { 'errors' => e.message }
        end
    end

    def local_server_params
      {
        template: template,
        name: "build checker test-#{test_vm_count}",
        hostname: HOSTNAME
      }
    end

    def onapp_server_params
      { body:
        { virtual_machine: new_local_vm.prepare_onapp_params.merge(note: 'cloud.net test built') }
      }
    end

    def test_vm_count
      Server.where(user: nil, hostname: HOSTNAME).count
    end

    def template
      @template ||= ubuntu_template || first_linux_template
    end

    def ubuntu_template
      Datacentre.first.templates.where(os_distro: 'ubuntu').first
    end

    def first_linux_template
      Datacentre.first.templates.where(os: 'linux').first
    end
  end
end
