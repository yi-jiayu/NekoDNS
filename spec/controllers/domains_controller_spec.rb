require 'rails_helper'

RSpec.describe DomainsController, type: :controller do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe '#destroy' do
    let(:domain) { create(:domain, user: user) }
    let(:id) { domain.id }

    before do
      allow(DomainService.instance).to receive(:delete_domain).and_return(true)
    end

    it 'calls DomainService#delete_domain' do
      expect(DomainService.instance).to receive(:delete_domain).with(domain)
      delete :destroy, params: { id: id }
    end

    it 'flashes a notice that the domain was deleted' do
      delete :destroy, params: { id: id }
      expect(flash.notice).to eq('Domain deleted!')
    end

    it 'redirects to the domains list' do
      delete :destroy, params: { id: id }
      expect(response).to redirect_to(domains_path)
    end

    context 'when the domain cannot be deleted because it still has records left' do
      before do
        allow(DomainService.instance).to receive(:delete_domain).and_raise(DomainService::Errors::DomainNotEmpty)
      end

      it 'flashes an alert with the reason' do
        delete :destroy, params: { id: id }
        expect(flash.alert).to eq('Your domain could not be deleted because it contains records other than the default SOA and NS records.')
      end

      it 'redirects to the domain page' do
        delete :destroy, params: { id: id }
        expect(response).to redirect_to(domain)
      end
    end

    context 'when the domain could not be deleted for some other reason' do
      before do
        allow(DomainService.instance).to receive(:delete_domain).and_return(false)
      end

      it 'flashes an alert' do
        delete :destroy, params: { id: id }
        expect(flash.alert).to eq('An unknown error occurred while trying to delete your domain.')
      end

      it 'redirects to the domain page' do
        delete :destroy, params: { id: id }
        expect(response).to redirect_to(domain)
      end
    end

    context 'when the domain does not belong to the current user' do
      let(:domain) { create(:domain) }

      it 'does not call DomainService#delete_domain' do
        expect(DomainService.instance).not_to receive(:delete_domain)
        delete :destroy, params: { id: id }
      end

      it 'flashes an error message' do
        delete :destroy, params: { id: id }
        expect(flash.alert).to eq("Can't delete a domain that doesn't exist!")
      end

      it 'redirects to the domains list' do
        delete :destroy, params: { id: id }
        expect(response).to redirect_to(domains_path)
      end
    end

    context 'when the domain does not exist' do
      let(:id) { -1 }

      it 'flashes an error message' do
        delete :destroy, params: { id: id }
        expect(flash.alert).to eq("Can't delete a domain that doesn't exist!")
      end

      it 'redirects to the domain list' do
        delete :destroy, params: { id: id }
        expect(response).to redirect_to(domains_path)
      end
    end
  end
end
