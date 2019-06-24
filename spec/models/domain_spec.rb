require 'rails_helper'

RSpec.describe Domain, type: :model do
  describe '.records' do
    let(:route53_client) { double(Aws::Route53::Client) }
    let(:records) { [
        build(:record, :soa),
        build(:record, :ns),
    ] }

    before do
      allow(Aws::Route53::Client).to receive(:new).and_return(route53_client)
      allow(route53_client).to receive(:list_resource_record_sets).and_return(list_resource_record_sets_response(records))
    end

    it 'returns a list of records' do
      expect(subject.records).to eq(records)
    end
  end
end


def list_resource_record_sets_response(records)
  Aws::Route53::Types::ListResourceRecordSetsResponse.new(
      resource_record_sets: records.group_by(&:type).map do |type, records|
        Aws::Route53::Types::ResourceRecordSet.new(
            name: records.first.name,
            type: type,
            ttl: records.first.ttl,
            resource_records: records.map { |record| Aws::Route53::Types::ResourceRecord.new(value: record.value) }
        )
      end
  )
end