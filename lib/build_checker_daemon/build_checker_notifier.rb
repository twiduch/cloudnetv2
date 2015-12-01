module BuildChecker
  # Resonsible for actions when test VM is not building properly
  # TODO: support ticket creation
  class Notifier
    extend Cloudnet::Logger

    class << self
      def test_vm_not_built
        Email.test_vm_not_built.deliver
      rescue => e
        logger.warn 'Email not sent: not created Test VM'
        logger.warn e.message
      end

      def test_vm_left
        Email.test_vm_left.deliver
      rescue => e
        logger.warn 'Email not sent: not destroyed Test VM'
        logger.warn e.message
      end
    end
  end
end
