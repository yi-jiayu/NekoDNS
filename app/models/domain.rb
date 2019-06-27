class Domain < ApplicationRecord
  belongs_to :user
  before_create :generate_route53_create_hosted_zone_caller_reference

  def records
    DomainService.instance.list_records(route53_hosted_zone_id)
  end

  private

  def generate_route53_create_hosted_zone_caller_reference
    self.route53_create_hosted_zone_caller_reference ||= SecureRandom.uuid
  end
end
