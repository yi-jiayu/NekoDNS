class DomainsController < ApplicationController
  before_action :set_current_domain, except: [:index, :new, :create]

  def index
    @domains = current_user.domains
  end

  def new
    @credentials = current_user.credentials
  end

  def create
    root = create_params.require(:root).delete_suffix('.')
    managed = create_params[:managed] != 'false'

    if managed && !Features.enabled?(:managed_domains)
      flash.alert = 'Managed zones are currently not enabled!'
      return render :new
    end

    credential = Credential.find_by(id: create_params.require(:credential_id).to_i, user: current_user) unless managed
    if !managed && credential.nil?
      flash.alert = 'Credentials not found!'
      return render :new
    end
    domain = CreateZone.call(current_user, root, credential)
    redirect_to domain
  rescue CreateZone::ZoneAlreadyExists
    flash.alert = 'You have already created a zone with that root!'
    redirect_to new_domain_path
  rescue Credential::AccessDenied
    flash.alert = 'The selected credentials were rejected by AWS. Is your policy set up correctly?'
    render :new
  end

  def delete
  end

  def destroy
    begin
      deleted = DeleteZone.call(@domain)
    rescue DeleteZone::ZoneNotEmpty
      flash.alert = 'your zone could not be deleted because it contains records other than the default SOA and NS records.'
      return redirect_to(@domain)
    end
    unless deleted
      flash.alert = 'An unknown error occurred while trying to delete your domain.'
      return redirect_to(@domain)
    end
    flash.notice = 'Zone deleted!' if deleted
    redirect_to domains_path
  end

  def show
  end

  private

  def create_params
    params.permit(:root, :managed, :credential_id)
  end

  def set_current_domain
    @domain = Domain.find_by(root: params[:root], user: current_user)
    if @domain.nil?
      flash.alert = 'Zone not found!'
      redirect_to(domains_path)
    end
  end
end
