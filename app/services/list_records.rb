class ListRecords < ApplicationService
  def initialize(domain)
    @domain = domain
    @client = Route53Client.new(domain.credential)
  end

  def call
    response = @client.list_resource_record_sets(hosted_zone_id: @domain.route53_hosted_zone_id)
    record_sets = response.resource_record_sets
    record_sets.flat_map do |record_set|
      record_set.resource_records.map do |record|
        Record.new(name: record_set.name, value: record.value, type: record_set.type, ttl: record_set.ttl)
      end
    end
  end
end
