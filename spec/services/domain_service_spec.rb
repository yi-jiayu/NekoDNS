require 'rails_helper'

RSpec.describe DomainService do
  subject { DomainService.instance }

  let(:route53_client) { double(Aws::Route53::Client) }
  let(:hosted_zone_id) { 'hosted zone ID' }

  before do
    allow(DomainService.instance).to receive(:client).and_return(route53_client)
  end

  describe '.create_domain' do
    let(:user) { create(:user) }
    let(:root) { 'example.com.' }
    let(:domain) { create(:domain, user: user) }

    before do
      allow(Domain).to receive(:new).and_return(domain)
      allow(route53_client).to receive(:create_hosted_zone).and_return(create_hosted_zone_response(hosted_zone_id))
    end

    it 'creates a new Route53 Hosted Zone' do
      expected_arguments = {
          name: domain.root,
          caller_reference: domain.route53_create_hosted_zone_caller_reference,
          hosted_zone_config: {
              comment: "Hosted zone created for #{domain.user.name} (#{domain.user.id}) by NekoDNS",
          },
      }
      expect(route53_client).to receive(:create_hosted_zone).with(expected_arguments)
      subject.create_domain(user, root)
    end

    it 'returns the created domain' do
      domain = subject.create_domain(user, root)
      expect(domain).to eq(Domain.last)
    end

    it 'sets the hosted zone ID on the domain' do
      domain = subject.create_domain(user, root)
      expect(domain.reload.route53_hosted_zone_id).to eq(hosted_zone_id)
    end

    context 'when a domain belonging to the user with the same root already exists' do
      let!(:existing_domain) { create(:domain, user: user, root: root) }

      before do
        allow(Domain).to receive(:new).and_call_original
      end

      it 'does not create a new domain' do
        domain = subject.create_domain(user, root)
        expect(domain.id).to eq(existing_domain.id)
      end
    end
  end
end


def create_hosted_zone_response(hosted_zone_id)
  Aws::Route53::Types::CreateHostedZoneResponse.new(
      hosted_zone: Aws::Route53::Types::HostedZone.new(id: hosted_zone_id),
  )
end