class ApplicationController < ActionController::Base
  before_action :require_login

  private

  def current_user
    return unless session[:user_id]
    User.find(session[:user_id])
  end

  def require_login
    unless current_user
      flash.alert = "You must be logged in to access this section"
      redirect_to login_url
    end
  end
end
