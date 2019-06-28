class DomainsController < ApplicationController
  def index
    @domains = current_user.domains
  end

  def new
  end

  def create
    root = params.require(:root)
    domain = DomainService.instance.create_domain(current_user, root)
    redirect_to domain
  end

  def destroy
    domain = Domain.find_by(id: params.require(:id), user: current_user)
    if domain.nil?
      flash.alert = "Can't delete a domain that doesn't exist!"
      return redirect_to(domains_path)
    end
    begin
      deleted = DomainService.instance.delete_domain(domain)
    rescue DomainService::Errors::DomainNotEmpty
      flash.alert = 'Your domain could not be deleted because it contains records other than the default SOA and NS records.'
      return redirect_to(domain)
    end
    unless deleted
      flash.alert = 'An unknown error occurred while trying to delete your domain.'
      return redirect_to(domain)
    end
    flash.notice = 'Domain deleted!' if deleted
    redirect_to domains_path
  end

  def show
    @domain = Domain.find(params[:id])
  end
end
