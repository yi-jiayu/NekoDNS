module ControllerHelpers
  def login_as(user)
    request.session[:user_id] = user.id
  end

  def permitted_params(h)
    ActionController::Parameters.new(h).permit!
  end
end