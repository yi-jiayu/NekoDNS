require 'rails_helper'

RSpec.describe Domain, type: :model do
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

    it "calls DomainService#list_records with the domain's route53_hosted_zone_id and returns the result" do
      expect(DomainService.instance).to receive(:list_records).with(domain.route53_hosted_zone_id).and_return(records)
      expect(domain.records).to eq(records)
    end
  end
end
