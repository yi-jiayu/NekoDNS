class DomainService
  include Singleton

  def create_domain(user, root)
    domain = Domain.find_or_create_by(user: user, root: root)
    raise Errors::DomainAlreadyExists.new if domain.route53_hosted_zone_id.present?

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

  def delete_domain(domain)
    client.delete_hosted_zone(id: domain.route53_hosted_zone_id)
    domain.destroy
  rescue Aws::Route53::Errors::HostedZoneNotEmpty
    raise Errors::DomainNotEmpty.new
  end

  def set_record(domain, record)
    params = {
      change_batch: {
        changes: [{
                    action: 'CREATE',
                    resource_record_set: {
                      name: record.name,
                      resource_records: [{ value: record.value }],
                      ttl: record.ttl,
                      type: record.type,
                    } }],
        comment: "Record set created for #{domain.user} #{domain.user.id} by NekoDNS",
      },
      hosted_zone_id: domain.route53_hosted_zone_id,
    }
    client.change_resource_record_sets(params)
  rescue Aws::Route53::Errors::InvalidInput, Aws::Route53::Errors::InvalidChangeBatch
    raise Errors::RecordInvalid.new
  end

  module Errors
    class DomainAlreadyExists < StandardError
      def message
        'Domain already exists'
      end
    end

    class DomainNotEmpty < StandardError
      def message
        'Domain not empty'
      end
    end

    class RecordInvalid < StandardError
      def message
        'Record invalid'
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
end