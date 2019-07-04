require 'rails_helper'

RSpec.describe SetRecord do
  let(:route53_client) { double(Aws::Route53::Client) }

  before do
    allow(Route53Client).to receive(:new).and_return(route53_client)
  end

  describe '#initialize' do
    let(:domain) { create(:domain) }
    let(:record) { build(:record) }

    context 'the provided domain does not have a credential' do
      it 'creates a Route53Client with no credential' do
        SetRecord.new(domain, record)
        expect(Route53Client).to have_received(:new).with(nil)
      end
    end

    context 'the provided domain has a credential' do
      let(:domain) { create(:domain, :with_credential) }

      it 'creates a Route53Client with it' do
        SetRecord.new(domain, record)
        expect(Route53Client).to have_received(:new).with(domain.credential)
      end
    end
  end

  describe '#call' do
    subject { SetRecord.new(domain, record) }

    let(:hosted_zone_id) { 'Z3M3LMPEXAMPLE' }
    let(:domain) { create(:domain, route53_hosted_zone_id: hosted_zone_id) }
    let(:record) { build(:record, name: 'example.com', value: '192.0.2.44', ttl: 60, type: 'A') }

    before do
      allow(route53_client).to receive(:change_resource_record_sets)
    end

    it 'calls Aws::Route53::Client#change_resource_record_sets' do
      params = {
        change_batch: {
          changes: [
            {
              action: "CREATE",
              resource_record_set: {
                name: "example.com",
                resource_records: [
                  {
                    value: "192.0.2.44",
                  },
                ],
                ttl: 60,
                type: "A",
              },
            },
          ],
          comment: "Record set created for #{domain.user} #{domain.user.id} by NekoDNS",
        },
        hosted_zone_id: "Z3M3LMPEXAMPLE",
      }
      subject.call
      expect(route53_client).to have_received(:change_resource_record_sets).with(params)
    end

    context 'when the client raises Aws::Route53::Errors::InvalidChangeBatch' do
      before do
        allow(route53_client).to receive(:change_resource_record_sets).and_raise(Aws::Route53::Errors::InvalidChangeBatch.new(nil, "[RRSet with DNS name example.com. is not permitted in zone example.com.]"))
      end

      it 'raises SetRecord::RecordInvalid' do
        expect { subject.call }.to raise_error(SetRecord::RecordInvalid)
      end
    end

    context 'when the client raises Aws::Route53::Errors::InvalidInput' do
      before do
        allow(route53_client).to receive(:change_resource_record_sets).and_raise(Aws::Route53::Errors::InvalidInput.new(nil, "1 validation error detected: Value '-1' at 'changeBatch.changes.1.member.resourceRecordSet.tTL' failed to satisfy constraint: Member must have value greater than or equal to 0"))
      end

      it 'raises SetRecord::RecordInvalid' do
        expect { subject.call }.to raise_error(SetRecord::RecordInvalid)
      end
    end
  end
end
