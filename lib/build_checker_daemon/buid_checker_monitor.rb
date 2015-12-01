module BuildChecker
  # Transaction daemon is responsible for updating local server collection
  # TODO: We should monitor pending transactions. For now we assume
  #       server is built if VM changed status to :on
  class Monitor
    include Cloudnet::Logger
    attr_reader :server, :start_time

    MAX_TIME_FOR_BUILT = 5.minutes
    CHECK_EVERY = 30.seconds

    def self.check(server)
      object = new(server)
      object.check
      object
    end

    def success
      return unless built?
      logger.info "Test server built: #{server.inspect}"
      yield if block_given?
    end

    def error
      return unless not_built?
      logger.error "Test server not built properly: #{server.inspect}"
      yield if block_given?
    end

    def initialize(server)
      @server = server
    end

    def check
      return @vm_built = false if onapp_error?

      wait_for_server_built
      try_direct_call unless server_on? # In case of transaction daemon failure
      @vm_built = server_on?
    end

    def try_direct_call
      server.state = :on if onapp_details['virtual_machine'].try(:[], 'booted')
    end

    def onapp_details
      OnappAPI.admin :get, "virtual_machines/#{server.onapp_identifier}"
    rescue => e
      { 'errors' => e.message }
    end

    def wait_for_server_built
      @start_time = Time.now
      reload_server until server_on? || wait_time_expired?
    end

    def reload_server
      sleep CHECK_EVERY
      server.reload
    end

    def server_on?
      server.state == :on
    end

    def onapp_error?
      !server.is_a?(Server)
    end

    def wait_time_expired?
      ((Time.now - start_time) / MAX_TIME_FOR_BUILT).floor > 0
    end

    def built?
      @vm_built == true
    end

    def not_built?
      !built?
    end
  end
end
