class CredentialsController < ApplicationController
  def index
    @credentials = current_user.credentials
  end

  def new
    @credential = Credential.new
    @credential.generate_external_id
  end

  def create
    @credential = Credential.create(credential_params.merge(user: current_user))
    return render :new unless @credential.errors.empty?
    redirect_to @credential
  end

  def show
    @credential = Credential.find(params[:id])
  end

  private

  def credential_params
    params.require(:credential).permit(:name, :external_id, :signed_external_id, :arn)
  end
end
