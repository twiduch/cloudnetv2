# Cloud.net has a very important relationship with OnApp so make sure the 2 systems are as compatible as possible
module OnappChecks
  extend ActiveSupport::Concern

  included do
    attr_accessor :onappcp_version

    # The version of OnApp's API which this code is currently tested against
    REQUIRED_ONAPP_API_VERSION = '4.1.0'
  end

  class_methods do
    # OnApp has various roles with differing levels of permissions. Cloud.net should use a dedicated role that has more
    # power than a standard user but less power than the OnApp admin role.
    # TODO: Specify the exact minimum permissions for this role and the admin role
    def onapp_cloudnet_role
      role = ENV['ONAPP_CLOUDNET_ROLE']
      fail "Invalid OnApp role ID: #{role}" if role.nil? || (role.to_i < 1)
      role
    end

    # Check for API version mismatch.
    def check_onapp_api_version
      return if ENV['DISABLE_HTTP_CHECKS'] == 'true'
      # Version mismatch is checked differently during testing.
      return if Cloudnet.environment == 'test' || ENV['SKIP_ONAPP_API_CHECK']
      request_onapp_api_version
      return if @current_onapp_api_version == Cloudnet::REQUIRED_ONAPP_API_VERSION
      Cloudnet.logger.warn onapp_api_difference
    end

    # Fail (rather than just log a warning) about a version mismatch
    def check_onapp_api_version!
      request_onapp_api_version
      return if @current_onapp_api_version == Cloudnet::REQUIRED_ONAPP_API_VERSION
      fail onapp_api_difference
    end

    private

    def request_onapp_api_version
      Cloudnet.logger.info 'Checking OnApp version...'
      @current_onapp_api_version ||= OnappAPI.admin(:get, '/version')['version']
    end

    def onapp_api_difference
      "OnApp API version (#{@current_onapp_api_version}) differs from version that " \
      "cloud.net is tested against (#{Cloudnet::REQUIRED_ONAPP_API_VERSION})"
    end
  end
end
