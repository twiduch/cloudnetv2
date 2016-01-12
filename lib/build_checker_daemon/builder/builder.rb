module BuildChecker
  module Builder
    HOSTNAME = 'build-checker'
    # Responsible for building test VM in Onapp and local DB
    class Builder
      include Cloudnet::Logger
      attr_reader :template

      def self.build_test_vm(tmpl)
        new(tmpl).build_test_vm
      end

      def initialize(tmpl)
        @template = tmpl
      end
    
      def build_test_vm
        return ['No template'] if template.nil?
        return new_onapp_vm['errors'] if new_onapp_vm['errors'].present?
        save_local_vm
      end

      def save_local_vm
        new_local_vm.onapp_identifier = new_onapp_vm['virtual_machine']['identifier']
        new_local_vm.save!
        logger.info "Test VM scheduled for build: #{new_local_vm.onapp_identifier}"
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
          name: "test template_id #{template.id}",
          hostname: HOSTNAME
        }
      end

      def onapp_server_params
        { body:
          { virtual_machine: new_local_vm.prepare_onapp_params.merge(note: 'cloud.net test built') }
        }
      end
    end
  end
end
