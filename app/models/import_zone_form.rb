class ImportZoneForm
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :hosted_zone_id, :credential_id

  validates :hosted_zone_id, :credential_id, presence: true
  validate :credential_exists

  private

  def credential_exists
    errors.add(:credential_id, 'not found') unless Credential.exists?(credential_id)
  end
end