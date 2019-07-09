require 'rails_helper'

RSpec.describe ImportZone do
  let(:user) { create(:user) }
  let(:root) { Faker::Internet.domain_name }
  let(:credential) { create(:credential) }
  let(:route53_client) { double(Aws::Route53::Client) }
  let(:hosted_zone_id) { 'OTSRAQTFHZTN' }

  before do
    allow(Route53Client).to receive(:new).and_return(route53_client)
  end

  describe '#initialize' do
    it 'creates a Route53Client with the provided credential' do
      ImportZone.new(user, hosted_zone_id, credential)
      expect(Route53Client).to have_received(:new).with(credential)
    end
  end

  describe '#call' do
    subject { ImportZone.new(user, hosted_zone_id, credential) }

    let(:zone) { build(:zone) }

    before do
      allow(route53_client).to receive(:get_hosted_zone).and_return(get_hosted_zone_response(root))
    end

    it 'creates a new hosted zone belonging to the user' do
      subject.call
      expect(user.zones.find_by(root: root,
                                route53_hosted_zone_id: hosted_zone_id,
                                credential: credential,
      )).to be_present
    end

    it 'returns the new zone' do
      return_value = subject.call
      expect(return_value).to eq(Zone.last)
    end

    context 'when get_hosted_zone raises Aws::Route53::Errors::AccessDenied' do
      before do
        allow(route53_client).to receive(:get_hosted_zone).and_raise(Aws::Route53::Errors::AccessDenied.new(nil, "User: #{credential.arn}/NekoDNS is not authorized to perform: route53:GetHostedZone on resource: arn:aws:route53:::hostedzone/#{hosted_zone_id}"))
      end

      it 'raises Credential::AccessDenied' do
        expect { subject.call }.to raise_error(Credential::AccessDenied)
      end
    end

    context 'when get_hosted_zone raises Aws::Route53::Errors::NoSuchHostedZone' do
      before do
        allow(route53_client).to receive(:get_hosted_zone).and_raise(Aws::Route53::Errors::NoSuchHostedZone.new(nil, "No hosted zone found with ID: #{hosted_zone_id}"))
      end

      it 'raises ImportZone::NoSuchHostedZone' do
        expect { subject.call }.to raise_error(ImportZone::NoSuchHostedZone)
      end
    end
  end
end

def get_hosted_zone_response(name)
  Aws::Route53::Types::GetHostedZoneResponse.new(
    hosted_zone: Aws::Route53::Types::HostedZone.new(name: name + '.')
  )
end