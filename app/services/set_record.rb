class SetRecord < ApplicationService
  attr_reader :domain, :record, :client

  def initialize(domain, record)
    @domain = domain
    @record = record
    @client = Route53Client.new(domain.credential)
  end

  def call
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
    raise RecordInvalid.new
  end

  class RecordInvalid < StandardError
  end
end