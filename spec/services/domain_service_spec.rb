require 'rails_helper'

RSpec.describe DomainService do
  let(:route53_client) { double(Aws::Route53::Client) }
  let(:hosted_zone_id) { 'hosted zone ID' }

  before do
    allow(Aws::Route53::Client).to receive(:new).and_return(route53_client)
  end

  describe '#initialize' do
    context 'when no credential is provided' do
      it 'initialises an Aws::Route53::Client using default credentials' do
        expect(Aws::Route53::Client).to receive(:new).with(no_args)
        described_class.new
      end

      it 'sets @client' do
        expect(described_class.new.client).to eq(route53_client)
      end
    end

    context 'when a credential is provided' do
      let(:credential) { build(:credential) }
      let(:assume_role_credentials) { double(Aws::AssumeRoleCredentials) }

      before do
        allow(Aws::AssumeRoleCredentials).to receive(:new).and_return(assume_role_credentials)
      end

      it 'builds an Aws::AssumeRoleCredentials' do
        expect(Aws::AssumeRoleCredentials).to receive(:new).with(role_arn: credential.arn,
                                                                 external_id: credential.external_id,
                                                                 role_session_name: 'NekoDNS')
        described_class.new(credential)
      end

      it 'initialises an Aws::Route53::Client using assume role credentials' do
        expect(Aws::Route53::Client).to receive(:new).with(credentials: assume_role_credentials)
        described_class.new(credential)
      end

      it 'sets @client' do
        expect(described_class.new(credential).client).to eq(route53_client)
      end

      context 'when Aws::AssumeRoleCredentials#new raises Aws::STS::Errors::AccessDenied' do
        before do
          allow(Aws::AssumeRoleCredentials).to receive(:new).and_raise(Aws::STS::Errors::AccessDenied.new(nil, 'Access denied'))
        end

        it 're-raises DomainService::Errors::AccessDenied' do
          expect { described_class.new(credential) }.to raise_error(DomainService::Errors::AccessDenied)
        end
      end
    end
  end

  describe '#create_domain' do
    let(:user) { create(:user) }
    let(:root) { Faker::Internet.domain_name }

    context "when the user has not created a domain with the given root before" do
      let(:domain) { create(:domain, user: user, root: root) }

      before do
        allow(route53_client).to receive(:create_hosted_zone).and_return(create_hosted_zone_response(hosted_zone_id))
      end

      it 'creates a new domain for the user' do
        expect(Domain).to receive(:new).with(user: user, root: root).and_call_original
        subject.create_domain(user, root)
      end

      it 'creates a new Route53 Hosted Zone' do
        allow(Domain).to receive(:new).and_return(domain)
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

      it 'returns the new domain' do
        allow(Domain).to receive(:new).and_return(domain)
        returned_domain = subject.create_domain(user, root)
        expect(returned_domain).to eq(domain)
      end

      it 'sets the hosted zone ID on the domain' do
        domain = subject.create_domain(user, root)
        expect(domain.reload.route53_hosted_zone_id).to eq(hosted_zone_id)
      end
    end

    context 'when a domain belonging to the user with the same root already exists' do
      context 'and it already has a hosted zone ID' do
        let!(:domain) { create(:domain, user: user, root: root, route53_hosted_zone_id: hosted_zone_id) }

        it 'does not create a new hosted zone' do
          expect(route53_client).not_to receive(:create_hosted_zone)
          suppress DomainService::Errors::DomainAlreadyExists do
            subject.create_domain(user, root)
          end
        end

        it 'does not create a new domain' do
          expect(Domain).not_to receive(:new)
          suppress DomainService::Errors::DomainAlreadyExists do
            subject.create_domain(user, root)
          end
        end

        it 'raises a DomainService::Errors::DomainAlreadyExists exception' do
          expect { subject.create_domain(user, root) }.to raise_error(DomainService::Errors::DomainAlreadyExists)
        end
      end
    end
  end

  describe '#list_records' do
    let(:records) { [
      build(:record, :soa),
      build(:record, :ns),
    ] }

    before do
      allow(route53_client).to receive(:list_resource_record_sets).and_return(list_resource_record_sets_response(records))
    end

    it "calls Aws::Route53::Client#list_resource_record_sets" do
      expect(route53_client).to receive(:list_resource_record_sets).with(hosted_zone_id: hosted_zone_id)
      subject.list_records(hosted_zone_id)
    end

    it 'returns a list of records' do
      expect(subject.list_records(hosted_zone_id)).to eq(records)
    end
  end

  describe '#delete_domain' do
    let(:domain) { create(:domain, route53_hosted_zone_id: hosted_zone_id) }

    before do
      allow(route53_client).to receive(:delete_hosted_zone)
    end

    it 'calls Aws::Route53::Client#delete_hosted_zone' do
      expect(route53_client).to receive(:delete_hosted_zone).with(id: hosted_zone_id)
      subject.delete_domain(domain)
    end

    it 'deletes the domain' do
      subject.delete_domain(domain)
      expect(Domain.exists?(id: domain.id)).to be false
    end

    context 'when the client raises Aws::Route53::Types::HostedZoneNotEmpty' do
      before do
        allow(route53_client).to receive(:delete_hosted_zone).and_raise(Aws::Route53::Errors::HostedZoneNotEmpty.new(nil, 'The specified hosted zone contains non-required resource record sets  and so cannot be deleted'))
      end

      it 're-raises DomainService::DomainNotEmpty' do
        expect { subject.delete_domain(domain) }.to raise_error(DomainService::Errors::DomainNotEmpty)
      end

      it 'does not delete the domain' do
        begin
          subject.delete_domain(domain)
        rescue
          expect(Domain.exists?(id: domain.id)).to be true
        end
      end
    end
  end

  describe '#set_record' do
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
      expect(route53_client).to receive(:change_resource_record_sets).with(params)
      subject.set_record(domain, record)
    end

    context 'when the client raises Aws::Route53::Errors::InvalidChangeBatch' do
      before do
        allow(route53_client).to receive(:change_resource_record_sets).and_raise(Aws::Route53::Errors::InvalidChangeBatch.new(nil, "[RRSet with DNS name example.com. is not permitted in zone example.com.]"))
      end

      it 're-raises DomainService::Errors::RecordInvalid' do
        expect { subject.set_record(domain, record) }.to raise_error(DomainService::Errors::RecordInvalid)
      end
    end

    context 'when the client raises Aws::Route53::Errors::InvalidInput' do
      before do
        allow(route53_client).to receive(:change_resource_record_sets).and_raise(Aws::Route53::Errors::InvalidInput.new(nil, "1 validation error detected: Value '-1' at 'changeBatch.changes.1.member.resourceRecordSet.tTL' failed to satisfy constraint: Member must have value greater than or equal to 0"))
      end

      it 're-raises DomainService::Errors::RecordInvalid' do
        expect { subject.set_record(domain, record) }.to raise_error(DomainService::Errors::RecordInvalid)
      end
    end
  end
end

def create_hosted_zone_response(hosted_zone_id)
  Aws::Route53::Types::CreateHostedZoneResponse.new(
    hosted_zone: Aws::Route53::Types::HostedZone.new(id: hosted_zone_id),
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