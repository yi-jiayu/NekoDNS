require 'rails_helper'

RSpec.describe ListRecords do
  let(:user) { create(:user) }
  let(:zone) { create(:zone, user: user) }
  let(:route53_client) { double(Aws::Route53::Client) }

  before do
    allow(Route53Client).to receive(:new).and_return(route53_client)
  end

  describe '#initialize' do
    context 'the provided zone does not have a credential' do
      it 'creates a Route53Client with no credential' do
        ListRecords.new(zone)
        expect(Route53Client).to have_received(:new).with(nil)
      end
    end

    context 'the provided zone has a credential' do
      let(:zone) { create(:zone, :with_credential, user: user) }

      it 'creates a Route53Client with it' do
        ListRecords.new(zone)
        expect(Route53Client).to have_received(:new).with(zone.credential)
      end
    end
  end

  describe '#call' do
    subject { ListRecords.new(zone) }

    let(:records) { [
      build(:record, :soa),
      build(:record, :ns),
    ] }

    before do
      allow(route53_client).to receive(:list_resource_record_sets).and_return(list_resource_record_sets_response(records))
    end

    it "calls Aws::Route53::Client#list_resource_record_sets" do
      subject.call
      expect(route53_client).to have_received(:list_resource_record_sets).with(hosted_zone_id: zone.route53_hosted_zone_id)
    end

    it 'returns a list of records' do
      expect(subject.call).to eq(records)
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