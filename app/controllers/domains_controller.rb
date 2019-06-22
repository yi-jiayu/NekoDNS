class DomainsController < ApplicationController
  def index
    @domains = current_user.domains
  end

  def new
  end

  def create
    root = params.require(:root)
    Domain.create(root: root, user: current_user)
    redirect to domains_path
  end
end
