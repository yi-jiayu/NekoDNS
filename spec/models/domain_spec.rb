require 'rails_helper'

RSpec.describe Domain, type: :model do
  describe '#to_param' do
    let(:domain) { build(:domain) }

    it 'is linked to by root' do
      expect(domain_path(domain)).to include(domain.root)
    end
  end

  context 'when created' do
    subject { build(:domain) }

    it 'generates a Route53 create_hosted_zone caller reference' do
      subject.route53_create_hosted_zone_caller_reference = nil
      subject.save
      expect(subject.reload.route53_create_hosted_zone_caller_reference).not_to be_nil
    end
  end

  describe '.records' do
    let(:domain) { build(:domain, route53_hosted_zone_id: 'hosted zone ID') }
    let(:records) { 'records' }

    before do
      allow(ListRecords).to receive(:call).and_return(records)
    end

    it "returns the result of ListRecords#call" do
      expect(domain.records).to eq(records)
      expect(ListRecords).to have_received(:call).with(domain)
    end
  end

  context 'before save' do
    let(:domain) { build(:domain, root: 'example.com.') }
    it 'removes trailing dots from the domain root' do
      domain.save
      expect(domain.reload.root).to eq('example.com')
    end
  end
end
