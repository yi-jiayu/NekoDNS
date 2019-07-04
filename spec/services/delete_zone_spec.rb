require 'rails_helper'

RSpec.describe DeleteZone do
  let(:user) { create(:user) }
  let(:domain) { create(:domain, user: user) }
  let(:route53_client) { double(Aws::Route53::Client) }

  before do
    allow(Route53Client).to receive(:new).and_return(route53_client)
  end

  describe '#initialize' do
    context 'the provided domain does not have a credential' do
      it 'creates a Route53Client with no credential' do
        DeleteZone.new(domain)
        expect(Route53Client).to have_received(:new).with(nil)
      end
    end

    context 'the provided domain has a credential' do
      let(:domain) { create(:domain, :with_credential, user: user) }

      it 'creates a Route53Client with it' do
        DeleteZone.new(domain)
        expect(Route53Client).to have_received(:new).with(domain.credential)
      end
    end
  end

  describe '#call' do
    subject { DeleteZone.new(domain) }

    before do
      allow(route53_client).to receive(:delete_hosted_zone)
    end

    it 'calls Aws::Route53::Client#delete_hosted_zone' do
      subject.call
      expect(route53_client).to have_received(:delete_hosted_zone).with(id: domain.route53_hosted_zone_id)
    end

    it 'deletes the domain' do
      subject.call
      expect(Domain.exists?(id: domain.id)).to be false
    end

    context 'when the client raises Aws::Route53::Types::HostedZoneNotEmpty' do
      before do
        allow(route53_client).
          to receive(:delete_hosted_zone).
            and_raise(Aws::Route53::Errors::HostedZoneNotEmpty.new(nil, 'The specified hosted zone contains non-required resource record sets and so cannot be deleted'))
      end

      it 'raises DeleteZone::ZoneNotEmpty' do
        expect { subject.call }.to raise_error(DeleteZone::ZoneNotEmpty)
      end

      it 'does not delete the domain' do
        suppress(DeleteZone::ZoneNotEmpty) do
          subject.call
        end
        expect(Domain.exists?(id: domain.id)).to be true
      end
    end
  end
end
