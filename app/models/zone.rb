class Zone < ApplicationRecord
  belongs_to :user
  belongs_to :credential, optional: true

  before_save :trim_trailing_dot_from_root
  before_create :generate_route53_create_hosted_zone_caller_reference

  def to_param
    root
  end

  def records
    ListRecords.call(self)
  end

  private

  def generate_route53_create_hosted_zone_caller_reference
    self.route53_create_hosted_zone_caller_reference ||= SecureRandom.uuid
  end

  def trim_trailing_dot_from_root
    self.root = root.delete_suffix('.')
  end
end
