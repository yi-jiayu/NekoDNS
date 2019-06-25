class ApplicationController < ActionController::Base
  before_action :require_login
  helper_method :current_user

  def current_user
    return unless session[:user_id]
    @current_user ||= User.find(session[:user_id])
  end

  def require_login
    unless current_user
      flash.alert = "You must be logged in to access this section"
      redirect_to login_url
    end
  end
end
