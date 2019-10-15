class Credential < ApplicationRecord
  belongs_to :user
  attr_accessor :signed_external_id
  validates :name, :arn, :external_id, presence: true
  validate :external_id_verified

  def generate_external_id
    self.external_id = SecureRandom.uuid
    @signed_external_id = verifier.generate(external_id, purpose: :external_id)
  end

  def external_id_verified
    if verifier.verified(signed_external_id, purpose: :external_id) != external_id
      errors.add(:external_id, 'invalid external ID')
    end
  end

  def self.human_attribute_name(attr, options = {})
    attr == 'external_id' ? 'External ID' : super
  end

  private

  def verifier
    @verifier ||= ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base)
  end

  class AccessDenied < StandardError
  end
end
