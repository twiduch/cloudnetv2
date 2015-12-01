# Callable methods to send email, just like Rails.
# Eg; Mailers.test_vm_not_built.deliver!
module Mailers
  def test_vm_not_built
    to ENV['MAILER_ADMIN_RECIPIENTS']
    subject 'Cloud.net: Not able to create VM'
  end

  def test_vm_left
    to ENV['MAILER_ADMIN_RECIPIENTS']
    subject 'Cloud.net: Test VM was not properly deleted'
  end
end
