class DomainsController < ApplicationController
  before_action :set_current_domain, except: [:index, :new, :create]

  def index
    @domains = current_user.domains
  end

  def new
    @credentials = current_user.credentials
  end

  def create
    unless Features.enabled?(:add_domain)
      flash.notice = 'Adding new domains is currently disabled.'
      return redirect_to domains_path
    end

    root = create_params.require(:root).delete_suffix('.')
    managed = create_params[:managed] != 'false'
    domain_service = if managed
                       DomainService.new
                     else
                       credential = Credential.find_by(id: create_params.require(:credential_id).to_i, user: current_user)
                       if credential.nil?
                         flash.alert = 'Credentials not found!'
                         return render :new
                       end
                       DomainService.new(credential)
                     end
    domain = domain_service.create_domain(current_user, root)
    redirect_to domain
  rescue DomainService::Errors::DomainAlreadyExists
    flash.alert = 'You have already created a domain with that root!'
    redirect_to new_domain_path
  rescue DomainService::Errors::AccessDenied
    flash.alert = 'The selected credentials were rejected by AWS. Is your policy set up correctly?'
    render :new
  end

  def delete
  end

  def destroy
    begin
      deleted = DomainService.new.delete_domain(@domain)
    rescue DomainService::Errors::DomainNotEmpty
      flash.alert = 'Your domain could not be deleted because it contains records other than the default SOA and NS records.'
      return redirect_to(@domain)
    end
    unless deleted
      flash.alert = 'An unknown error occurred while trying to delete your domain.'
      return redirect_to(@domain)
    end
    flash.notice = 'Domain deleted!' if deleted
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
      flash.alert = 'Domain not found!'
      redirect_to(domains_path)
    end
  end
end
