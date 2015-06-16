# Callable methods to send email, just like Rails.
# Eg; Mailers.welcome(user).deliver!
module Mailers
  def welcome(user)
    @user = user
    to @user.email
    subject 'Welcome to Cloud.net: please confirm your email'
  end
end
