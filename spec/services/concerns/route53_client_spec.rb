require 'rails_helper'

RSpec.describe Route53Client do
  describe '#new' do
    let(:route53_client) { double(Aws::Route53::Client) }

    before do
      allow(Aws::Route53::Client).to receive(:new).and_return(route53_client)
    end

    context 'when credential is nil' do
      it 'initialises an Aws::Route53::Client with no arguments' do
        Route53Client.new(nil)
        expect(Aws::Route53::Client).to have_received(:new).with(no_args)
      end

      it 'returns the client' do
        expect(Route53Client.new(nil)).to eq(route53_client)
      end
    end

    context 'when credential is provided' do
      let(:credential) { build(:credential) }
      let(:assume_role_credentials) { double(Aws::AssumeRoleCredentials) }

      before do
        allow(Aws::AssumeRoleCredentials).to receive(:new).and_return(assume_role_credentials)
      end

      it 'builds an Aws::AssumeRoleCredentials' do
        Route53Client.new(credential)
        expect(Aws::AssumeRoleCredentials).
          to have_received(:new).
            with(role_arn: credential.arn,
                 external_id: credential.external_id,
                 role_session_name: 'NekoDNS')
      end

      it 'initialises an Aws::Route53::Client using assume role credentials' do
        Route53Client.new(credential)
        expect(Aws::Route53::Client).to have_received(:new).with(credentials: assume_role_credentials)
      end

      it 'returns the client' do
        expect(Route53Client.new(credential)).to eq(route53_client)
      end

      context 'when Aws::AssumeRoleCredentials#new raises Aws::STS::Errors::AccessDenied' do
        before do
          allow(Aws::AssumeRoleCredentials).to receive(:new).and_raise(Aws::STS::Errors::AccessDenied.new(nil, 'Access denied'))
        end

        it 'raises Credential::AccessDenied' do
          expect { Route53Client.new(credential) }.to raise_error(Credential::AccessDenied)
        end
      end
    end
  end
end
