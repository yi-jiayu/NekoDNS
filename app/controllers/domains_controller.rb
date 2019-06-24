class DomainsController < ApplicationController
  def index
    @domains = current_user.domains
  end

  def new
  end

  def create
    root = params.require(:root)
    domain = DomainService.create_domain(current_user, root)
    redirect_to domain
  end

  def show
    @domain = Domain.find(params[:id])
  end
end
