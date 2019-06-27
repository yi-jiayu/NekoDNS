class DomainService
  include Singleton

  def create_domain(user, root)
    root = root + '.' unless fully_qualified(root)
    domain = Domain.find_or_create_by(user: user, root: root)
    response = client.create_hosted_zone(
        name: domain.root,
        caller_reference: domain.route53_create_hosted_zone_caller_reference,
        hosted_zone_config: {
            comment: comment_for(domain),
        },
    )
    domain.update(route53_hosted_zone_id: response.hosted_zone.id)
    domain
  end

  def list_records(hosted_zone_id)
    response = client.list_resource_record_sets(hosted_zone_id: hosted_zone_id)
    record_sets = response.resource_record_sets
    record_sets.flat_map do |record_set|
      record_set.resource_records.map do |record|
        Record.new(name: record_set.name, value: record.value, type: record_set.type, ttl: record_set.ttl)
      end
    end
  end

  private

  def client
    @client ||= Aws::Route53::Client.new
  end

  def comment_for(domain)
    "Hosted zone created for #{domain.user.name} (#{domain.user.id}) by NekoDNS"
  end

  def fully_qualified(root)
    root[-1] == '.'
  end
end