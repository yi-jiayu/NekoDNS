require 'rails_helper'

RSpec.describe Domain, type: :model do
  describe '#ready?' do
    context 'when the domain does not have a SOA record nor any NS records' do
      subject { create(:domain) }

      it 'is not ready' do
        expect(subject.ready?).to be false
      end
    end

    context 'when the domain has a SOA record and at least one NS record' do
      subject do
        create(:domain) do |domain|
          create(:record, :soa, domain: domain)
          create(:record, :ns, domain: domain)
          create(:record, :ns, domain: domain)
        end
      end

      it 'is ready' do
        expect(subject.ready?).to be true
      end
    end
  end
end
