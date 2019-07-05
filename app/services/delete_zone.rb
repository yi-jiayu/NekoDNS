class DeleteZone < ApplicationService
  def initialize(zone)
    @zone = zone
    @client = Route53Client.new(zone.credential)
  end

  def call
    @client.delete_hosted_zone(id: @zone.route53_hosted_zone_id)
    @zone.destroy
  rescue Aws::Route53::Errors::HostedZoneNotEmpty
    raise ZoneNotEmpty.new
  end

  class ZoneNotEmpty < StandardError
  end
end