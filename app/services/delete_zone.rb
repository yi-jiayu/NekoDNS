class DeleteZone < ApplicationService
  def initialize(domain)
    @domain = domain
    @client = Route53Client.new(domain.credential)
  end

  def call
    @client.delete_hosted_zone(id: @domain.route53_hosted_zone_id)
    @domain.destroy
  rescue Aws::Route53::Errors::HostedZoneNotEmpty
    raise ZoneNotEmpty.new
  end

  class ZoneNotEmpty < StandardError
  end
end