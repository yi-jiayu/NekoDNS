require 'rails_helper'

RSpec.describe Credential, type: :model do
  context 'when external ID is not present' do
    let(:credential) { build(:credential) }

    before do
      credential.external_id = nil
    end

    it 'is invalid' do
      expect(credential).to be_invalid
    end
  end

  describe '#generate_external_id' do
    let(:credential) { build(:credential, external_id: nil) }
    let(:verifier) { ActiveSupport::MessageVerifier.new 's3Krit' }

    before do
      allow(credential).to receive(:verifier).and_return(verifier)
    end

    it 'generates an external ID' do
      credential.generate_external_id
      expect(credential.external_id).to be_present
    end

    it 'generates a signed external ID' do
      credential.generate_external_id
      expect(credential.signed_external_id).to eq(verifier.generate(credential.external_id, purpose: :external_id))
    end
  end

  context 'when signed_external_id corresponds to external_id' do
    let(:credential) { build(:credential) }
    let(:verifier) { ActiveSupport::MessageVerifier.new 's3Krit' }
    let(:signed_external_id) { verifier.generate(credential.external_id, purpose: :external_id) }

    before do
      allow(credential).to receive(:verifier).and_return(verifier)
      credential.instance_variable_set(:@signed_external_id, signed_external_id)
    end

    it 'is valid' do
      expect(credential).to be_valid
    end
  end

  context 'when signed_external_id does not correspond to external_id' do
    let(:credential) { build(:credential) }

    before do
      credential.signed_external_id = 'hello'
    end

    it 'is invalid' do
      expect(credential).to be_invalid
    end
  end
end
