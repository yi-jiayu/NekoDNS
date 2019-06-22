class DomainsController < ApplicationController
  def index
    @domains = current_user.domains
  end

  def new
  end
end
