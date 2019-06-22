require 'rails_helper'


RSpec.describe CreateRoute53HostedZoneJob, type: :job do
  describe '#perform' do
    context 'when the Route53 create_hosted_zone caller reference is set on the domain' do
      let(:domain) { create(:domain, :with_route53_create_hosted_zone_caller_reference) }
      let(:route53_client) { double(Aws::Route53::Client) }
      let(:hosted_zone_id) { 'hosted zone ID' }
      let(:records) { [build(:record, :soa), build(:record, :ns), build(:record, :ns)] }

      before do
        allow(Aws::Route53::Client).to receive(:new).and_return(route53_client)
        allow(route53_client).to receive(:create_hosted_zone).and_return(create_hosted_zone_response(hosted_zone_id))
        allow(route53_client).to receive(:get_change).and_return(get_change_response('INSYNC'))
        allow(route53_client).to receive(:list_resource_record_sets).and_return(list_resource_record_sets_response(records))
      end

      it "calls the Route53 client's create_hosted_zone method" do
        expected_arguments = {
            name: domain.root,
            caller_reference: domain.route53_create_hosted_zone_caller_reference,
            hosted_zone_config: {
                comment: "Hosted zone created for #{domain.user.name} (#{domain.user.id}) by NekoDNS",
            },
        }
        expect(route53_client).to receive(:create_hosted_zone).with(expected_arguments)
        subject.perform(domain)
      end

      it "sets the domain's Route53 Hosted Zone ID" do
        subject.perform(domain)
        expect(domain.reload.route53_hosted_zone_id).to eq(hosted_zone_id)
      end

      it "updates the domain's DNS records" do
        subject.perform(domain)
        domain.reload
        aggregate_failures do
          records.each do |record|
            record_exists = Record.exists?(domain: domain, name: record.name, type: record.type, value: record.value)
            expect(record_exists).to be(true), "expected domain to have record with #{{name: record.name, type: record.type, value: record.value}}"
          end
        end
      end

      it "waits for the change to be INSYNC before updating the domain's DNS records" do
        allow(subject).to receive(:sleep)
        expect(route53_client).to receive(:get_change).and_return(get_change_response('PENDING'), get_change_response('INSYNC'))
        subject.perform(domain)
      end
    end
  end
end

def change_info(status)
  Aws::Route53::Types::ChangeInfo.new(status: status)
end

def get_change_response(status)
  Aws::Route53::Types::GetChangeResponse.new(change_info: change_info(status))
end

def create_hosted_zone_response(hosted_zone_id)
  Aws::Route53::Types::CreateHostedZoneResponse.new(
      hosted_zone: Aws::Route53::Types::HostedZone.new(id: hosted_zone_id),
      change_info: change_info('PENDING'),
  )
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

