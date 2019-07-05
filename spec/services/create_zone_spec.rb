require 'rails_helper'

RSpec.describe CreateZone do
  let(:user) { create(:user) }
  let(:root) { Faker::Internet.domain_name }
  let(:route53_client) { double(Aws::Route53::Client) }
  let(:hosted_zone_id) { 'hosted zone ID' }

  before do
    allow(Route53Client).to receive(:new).and_return(route53_client)
  end

  describe '#initialize' do
    context 'when credential is nil' do
      it 'creates a Route53Client with no credential' do
        CreateZone.new(user, root)
        expect(Route53Client).to have_received(:new).with(nil)
      end
    end

    context 'when credential is provided' do
      let(:credential) { build(:credential) }

      it 'creates a Route53Client with the provided credential' do
        CreateZone.new(user, root, credential)
        expect(Route53Client).to have_received(:new).with(credential)
      end
    end
  end

  describe '#call' do
    subject { CreateZone.new(user, root) }

    context "when the user has not created a zone with the given root before" do
      let(:zone) { create(:zone, user: user, root: root) }

      before do
        allow(route53_client).to receive(:create_hosted_zone).and_return(create_hosted_zone_response(hosted_zone_id))
      end

      it 'creates a new zone for the user' do
        expect(Zone).to receive(:new).with(user: user, root: root).and_call_original
        subject.call
      end

      it 'creates a new Route53 Hosted Zone' do
        allow(Zone).to receive(:new).and_return(zone)
        expected_arguments = {
          name: zone.root,
          caller_reference: zone.route53_create_hosted_zone_caller_reference,
          hosted_zone_config: {
            comment: "Hosted zone created for #{zone.user.name} (#{zone.user.id}) by NekoDNS",
          },
        }
        expect(route53_client).to receive(:create_hosted_zone).with(expected_arguments)
        subject.call
      end

      it 'returns the new zone' do
        allow(Zone).to receive(:new).and_return(zone)
        returned_zone = subject.call
        expect(returned_zone).to eq(zone)
      end

      it 'sets the hosted zone ID on the zone' do
        zone = subject.call
        expect(zone.reload.route53_hosted_zone_id).to eq(hosted_zone_id)
      end

      context 'when a credential is provided while creating the zone' do
        subject { CreateZone.new(user, root, credential) }

        let(:credential) { create(:credential) }

        it 'associates the created zone with that credential' do
          zone = subject.call
          expect(zone.reload.credential).to eq(credential)
        end
      end
    end

    context 'when a zone belonging to the user with the same root already exists' do
      context 'and it already has a hosted zone ID' do
        let!(:zone) { create(:zone, user: user, root: root, route53_hosted_zone_id: hosted_zone_id) }

        it 'does not create a new hosted zone' do
          expect(route53_client).not_to receive(:create_hosted_zone)
          suppress CreateZone::ZoneAlreadyExists do
            subject.call
          end
        end

        it 'does not create a new zone' do
          expect(Zone).not_to receive(:new)
          suppress CreateZone::ZoneAlreadyExists do
            subject.call
          end
        end

        it 'raises CreateZone::ZoneAlreadyExists' do
          expect { subject.call }.to raise_error(CreateZone::ZoneAlreadyExists)
        end
      end
    end
  end
end

def create_hosted_zone_response(hosted_zone_id)
  Aws::Route53::Types::CreateHostedZoneResponse.new(
    hosted_zone: Aws::Route53::Types::HostedZone.new(id: hosted_zone_id),
  )
end