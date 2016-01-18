# Callable methods to send email, just like Rails.
# Eg; Email.welcome(user).deliver!
module Mailers
  def welcome(user)
    @user = user
    to @user.email
    subject 'Welcome to Cloud.net: please confirm your email'
  end

  def transaction_error(transaction_id)
    @transaction_id = transaction_id
    to ENV['CLOUDNET_SUPPORT_EMAIL']
    subject "Transaction log error on #{ENV['ONAPP_URI']}"
  end
end
