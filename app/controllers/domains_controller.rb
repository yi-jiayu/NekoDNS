class DomainsController < ApplicationController
  def index
    @domains = current_user.domains
  end

  def new
  end

  def create
    root = params.require(:root)
    domain = Domain.create(user: current_user, root: root)
    redirect_to domain
  end

  def show
    @domain = Domain.find(params[:id])
    flash.notice = 'Please wait, we are currently preparing the name servers for your domain.' unless @domain.ready?
  end
end
