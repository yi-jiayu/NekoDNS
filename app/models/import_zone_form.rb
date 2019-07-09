class ImportZoneForm
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :hosted_zone_id, :credential_id

  validates_presence_of :hosted_zone_id, :credential_id
  validate :credential_exists

  private

  def credential_exists
    errors.add(:credential_id, 'not found') unless Credential.exists?(credential_id)
  end
end