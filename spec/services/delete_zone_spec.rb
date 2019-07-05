require 'rails_helper'

RSpec.describe DeleteZone do
  let(:user) { create(:user) }
  let(:zone) { create(:zone, user: user) }
  let(:route53_client) { double(Aws::Route53::Client) }

  before do
    allow(Route53Client).to receive(:new).and_return(route53_client)
  end

  describe '#initialize' do
    context 'the provided zone does not have a credential' do
      it 'creates a Route53Client with no credential' do
        DeleteZone.new(zone)
        expect(Route53Client).to have_received(:new).with(nil)
      end
    end

    context 'the provided zone has a credential' do
      let(:zone) { create(:zone, :with_credential, user: user) }

      it 'creates a Route53Client with it' do
        DeleteZone.new(zone)
        expect(Route53Client).to have_received(:new).with(zone.credential)
      end
    end
  end

  describe '#call' do
    subject { DeleteZone.new(zone) }

    before do
      allow(route53_client).to receive(:delete_hosted_zone)
    end

    it 'calls Aws::Route53::Client#delete_hosted_zone' do
      subject.call
      expect(route53_client).to have_received(:delete_hosted_zone).with(id: zone.route53_hosted_zone_id)
    end

    it 'deletes the zone' do
      subject.call
      expect(Zone.exists?(id: zone.id)).to be false
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

      it 'does not delete the zone' do
        suppress(DeleteZone::ZoneNotEmpty) do
          subject.call
        end
        expect(Zone.exists?(id: zone.id)).to be true
      end
    end
  end
end
