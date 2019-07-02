class CredentialsController < ApplicationController
  def index
    @credentials = current_user.credentials
  end

  def new
    @credential = Credential.new
    session[:aws_external_id] = SecureRandom.uuid
  end

  def create
    @credential = Credential.create(user: current_user,
                                    name: credential_params[:name],
                                    arn: credential_params[:arn],
                                    external_id: session[:aws_external_id])
    return render :new unless @credential.errors.empty?
    session.delete(:aws_external_id)
    redirect_to @credential
  end

  def show
    @credential = Credential.find(params[:id])
  end

  private

  def credential_params
    params.require(:credential).permit(:name, :arn)
  end
end
