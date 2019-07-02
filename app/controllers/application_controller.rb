class ApplicationController < ActionController::Base
  before_action :set_raven_context if ENV['SENTRY_DSN'].present?
  before_action :require_login
  helper_method :current_user

  def current_user
    return unless session[:user_id]

    @current_user ||= User.find(session[:user_id])
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def require_login
    unless current_user
      flash.alert = "You must be logged in to access this section"
      redirect_to login_url
    end
  end

  def set_raven_context
    Raven.user_context(id: session[:user_id])
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end
end
