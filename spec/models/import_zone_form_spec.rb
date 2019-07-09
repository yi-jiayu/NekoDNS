require 'rails_helper'

RSpec.describe ImportZoneForm, type: :model do
  subject { ImportZoneForm.new(attributes) }

  describe 'when hosted_zone_id is not present' do
    let(:attributes) { attributes_for(:import_zone_form, :with_credential_id).except(:hosted_zone_id) }

    it 'is invalid' do
      expect(subject).to be_invalid
    end
  end

  describe 'when credential_id is not present' do
    let(:attributes) { attributes_for(:import_zone_form).except(:credential_id) }

    it 'is invalid' do
      expect(subject).to be_invalid
    end
  end

  describe 'when credential_id does not correspond to any credential' do
    let(:attributes) { attributes_for(:import_zone_form, credential_id: -1) }

    it 'is invalid' do
      expect(subject).to be_invalid
    end
  end
end
