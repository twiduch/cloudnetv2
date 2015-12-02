# Bare-minimum controller to get Active Admin working
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action do
    Cloudnet.current_user = "admin-#{current_admin_user.id}"
  end
end
