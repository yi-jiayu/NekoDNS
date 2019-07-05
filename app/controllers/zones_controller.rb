class ZonesController < ApplicationController
  before_action :set_current_zone, except: [:index, :new, :create]

  def index
    @zones = current_user.zones
  end

  def new
    @credentials = current_user.credentials
  end

  def create
    root = create_params.require(:root).delete_suffix('.')
    managed = create_params[:managed] != 'false'

    if managed && !Features.enabled?(:managed_zones)
      flash.alert = 'Managed zones are currently not enabled!'
      return render :new
    end

    if !managed && create_params[:credential_id].blank?
      flash.alert = 'You must specify a credential to use when creating an unmanaged zone.'
      return render :new
    end

    credential = Credential.find_by(id: create_params.require(:credential_id).to_i, user: current_user) unless managed
    if !managed && credential.nil?
      flash.alert = 'Credentials not found!'
      return render :new
    end
    zone = CreateZone.call(current_user, root, credential)
    redirect_to zone
  rescue CreateZone::ZoneAlreadyExists
    flash.alert = 'You have already created a zone with that root!'
    redirect_to new_zone_path
  rescue Credential::AccessDenied
    flash.alert = 'The selected credentials were rejected by AWS. Is your policy set up correctly?'
    render :new
  end

  def delete
  end

  def destroy
    begin
      deleted = DeleteZone.call(@zone)
    rescue DeleteZone::ZoneNotEmpty
      flash.alert = 'Your zone could not be deleted because it contains records other than the default SOA and NS records.'
      return redirect_to(@zone)
    end
    unless deleted
      flash.alert = 'An unknown error occurred while trying to delete your zone.'
      return redirect_to(@zone)
    end
    flash.notice = 'Zone deleted!' if deleted
    redirect_to zones_path
  end

  def show
  end

  private

  def create_params
    params.permit(:root, :managed, :credential_id)
  end

  def set_current_zone
    @zone = Zone.find_by(root: params[:root], user: current_user)
    if @zone.nil?
      flash.alert = 'Zone not found!'
      redirect_to(zones_path)
    end
  end
end
