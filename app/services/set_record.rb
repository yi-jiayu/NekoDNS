class SetRecord < ApplicationService
  attr_reader :zone, :record, :client

  def initialize(zone, record)
    @zone = zone
    @record = record
    @client = Route53Client.new(zone.credential)
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
        comment: "Record set created for #{zone.user} #{zone.user.id} by NekoDNS",
      },
      hosted_zone_id: zone.route53_hosted_zone_id,
    }
    client.change_resource_record_sets(params)
  rescue Aws::Route53::Errors::InvalidInput, Aws::Route53::Errors::InvalidChangeBatch
    raise RecordInvalid.new
  end

  class RecordInvalid < StandardError
  end
end