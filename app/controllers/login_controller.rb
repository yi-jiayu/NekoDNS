class LoginController < ApplicationController
  skip_before_action :require_login
end
