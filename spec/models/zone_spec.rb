require 'rails_helper'

RSpec.describe Zone, type: :model do
  describe '#to_param' do
    let(:zone) { build(:zone) }

    it 'is linked to by root' do
      expect(zone_path(zone)).to include(zone.root)
    end
  end

  context 'when created' do
    subject { build(:zone) }

    it 'generates a Route53 create_hosted_zone caller reference' do
      subject.route53_create_hosted_zone_caller_reference = nil
      subject.save
      expect(subject.reload.route53_create_hosted_zone_caller_reference).not_to be_nil
    end
  end

  describe '.records' do
    let(:zone) { build(:zone, route53_hosted_zone_id: 'hosted zone ID') }
    let(:records) { 'records' }

    before do
      allow(ListRecords).to receive(:call).and_return(records)
    end

    it "returns the result of ListRecords#call" do
      expect(zone.records).to eq(records)
      expect(ListRecords).to have_received(:call).with(zone)
    end
  end

  context 'before save' do
    let(:zone) { build(:zone, root: 'example.com.') }
    it 'removes trailing dots from the zone root' do
      zone.save
      expect(zone.reload.root).to eq('example.com')
    end
  end
end
