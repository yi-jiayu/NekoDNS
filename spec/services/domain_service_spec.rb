require 'rails_helper'

RSpec.describe DomainService do
  describe '.create_domain' do

    let(:user) { create(:user) }

    it 'creates a new domain' do
      before_count = Domain.count
      DomainService.create_domain(user, 'example.com')
      expect(Domain.count).to eq(before_count + 1)
    end

    it 'creates an SOA record and at least one NS record for the domain' do
      domain = DomainService.create_domain(user, 'example.com')
      expect(Record.where(domain: domain, type: 'SOA').count).to eq(1)
      expect(Record.where(domain: domain, type: 'NS').count).to be >= 1
    end
  end
end
