require 'rails_helper'

RSpec.describe Features do
  context 'when environment variable corresponding to feature is set to "true"' do
    let(:feature) { :create_zone }

    before do
      allow(Figaro.env).to receive(:CREATE_ZONE_ENABLED).and_return('true')
    end

    it 'returns true' do
      expect(Features.enabled?(feature)).to be true
    end
  end
end