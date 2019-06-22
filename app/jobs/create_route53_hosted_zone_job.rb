class CreateRoute53HostedZoneJob < ApplicationJob
  queue_as :default

  def perform(domain)
    client = Aws::Route53::Client.new
    create_hosted_zone_response = client.create_hosted_zone(
        name: domain.root,
        caller_reference: domain.route53_create_hosted_zone_caller_reference,
        hosted_zone_config: {
            comment: comment_for(domain),
        },
    )
    hosted_zone = create_hosted_zone_response.hosted_zone
    domain.route53_hosted_zone_id = hosted_zone.id
    domain.save

    change_info = create_hosted_zone_response.change_info
    loop do
      get_change_response = client.get_change(change_info.id)
      change_info = get_change_response.change_info
      break if change_info.status == 'INSYNC'

      sleep(1.minute)
    end

    list_resource_record_sets_response = client.list_resource_record_sets(hosted_zone_id: hosted_zone.id)
    record_sets = list_resource_record_sets_response.resource_record_sets
    Record.transaction do
      record_sets.each do |record_set|
        record_set.resource_records.each do |record|
          attributes = {domain: domain, name: record_set.name, value: record.value, type: record_set.type, ttl: record_set.ttl}
          Record.create(attributes) unless Record.exists?(attributes)
        end
      end
    end
  end

  private

  def comment_for(domain)
    "Hosted zone created for #{domain.user.name} (#{domain.user.id}) by NekoDNS"
  end
end
