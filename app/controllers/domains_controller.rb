class DomainsController < ApplicationController
  before_action :set_current_domain, except: [:index, :new, :create]

  def index
    @domains = current_user.domains
  end

  def new
  end

  def create
    root = params.require(:root).delete_suffix('.')
    domain = DomainService.instance.create_domain(current_user, root)
    redirect_to domain
  rescue DomainService::Errors::DomainAlreadyExists
    flash.alert = 'You have already created a domain with that root!'
    redirect_to new_domain_path
  end

  def delete
  end

  def destroy
    begin
      deleted = DomainService.instance.delete_domain(@domain)
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

  def set_current_domain
    @domain = Domain.find_by(root: params[:root], user: current_user)
    if @domain.nil?
      flash.alert = 'Domain not found!'
      redirect_to(domains_path)
    end
  end
end
