# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DomainsController, type: :controller do
  let(:user) { create(:user) }
  let(:domain) { create(:domain, user: user) }
  let(:root) { domain.root }
  let(:domain_service) { double(DomainService) }

  before do
    allow(DomainService).to receive(:new).and_return(domain_service)
    login_as(user)
  end

  describe '#create' do
    let(:params) { { root: root } }

    before do
      allow(domain_service).to receive(:create_domain).and_return(domain)
    end

    context 'when creating a managed domain' do
      let(:params) { { root: 'example.com', managed: 'true' } }

      it 'initialises the domain service object without credentials' do
        post :create, params: params
        expect(DomainService).to have_received(:new).with(no_args)
      end
    end

    context 'when creating a domain using user credentials' do
      let(:credential) { create(:credential, user: user) }
      let(:params) { { root: 'example.com', managed: 'false', credential_id: credential.id.to_s } }

      it 'initialises the domain service object with credentials' do
        post :create, params: params
        expect(DomainService).to have_received(:new).with(credential)
      end

      context 'when params[:credential_id] does not exist' do
        let(:params) { { root: 'example.com', managed: 'false', credential_id: '-1' } }

        it 'flashes an alert' do
          post :create, params: params
          expect(flash.alert).to eq('Credentials not found!')
        end

        it 'renders :new' do
          post :create, params: params
          expect(response).to render_template(:new)
        end
      end

      context 'when params[:credential_id] does not belong to the user' do
        let(:credential) { create(:credential) }

        it 'flashes an alert' do
          post :create, params: params
          expect(flash.alert).to eq('Credentials not found!')
        end

        it 'renders :new' do
          post :create, params: params
          expect(response).to render_template(:new)
        end
      end

      context 'when the provided credentials are invalid' do
        let(:domain_service) { double(DomainService) }

        before do
          allow(DomainService).to receive(:new).and_return(domain_service)
          allow(domain_service).to receive(:create_domain).and_raise(DomainService::Errors::AccessDenied)
        end

        it 'flashes an alert' do
          post :create, params: params
          expect(flash.alert).to eq('The selected credentials were rejected by AWS. Is your policy set up correctly?')
        end

        it 'renders :new' do
          post :create, params: params
          expect(response).to render_template(:new)
        end
      end
    end

    it 'calls DomainService#create_domain' do
      expect(domain_service).to receive(:create_domain).with(user, root)
      post :create, params: params
    end

    it 'redirects to the domain page' do
      post :create, params: params
      expect(response).to redirect_to(domain)
    end

    context 'when the create domain feature is disabled' do
      before do
        allow(Features).to receive(:enabled?).with(:add_domain).and_return(false)
      end

      it 'flashes a notice' do
        post :create, params: params
        expect(flash.notice).to eq('Adding new domains is currently disabled.')
      end

      it 'redirects to the domains index' do
        post :create, params: params
        expect(response).to redirect_to(domains_path)
      end

      it 'does not call DomainService#create_domain' do
        post :create, params: params
        expect(domain_service).not_to have_received(:create_domain)
      end
    end

    context 'when the provided domain root contains a trailing dot' do
      let(:root) { 'example.com.' }

      it 'removes it before calliinng DomainService#create_domain' do
        expect(domain_service).to receive(:create_domain).with(user, 'example.com')
        post :create, params: params
      end
    end

    context 'when DomainService#create_domain raises DomainService::Errors::DomainAlreadyExists' do
      before do
        allow(domain_service).to receive(:create_domain).and_raise(DomainService::Errors::DomainAlreadyExists)
      end

      it 'flashes an alert and redirects back to new' do
        post :create, params: params
        expect(flash.alert).to eq('You have already created a domain with that root!')
        expect(response).to redirect_to(new_domain_path)
      end
    end
  end

  describe '#destroy' do
    before do
      allow(DomainService.new).to receive(:delete_domain).and_return(true)
    end

    it 'calls DomainService#delete_domain' do
      expect(DomainService.new).to receive(:delete_domain).with(domain)
      delete :destroy, params: { root: root }
    end

    it 'flashes a notice that the domain was deleted' do
      delete :destroy, params: { root: root }
      expect(flash.notice).to eq('Domain deleted!')
    end

    it 'redirects to the domains list' do
      delete :destroy, params: { root: root }
      expect(response).to redirect_to(domains_path)
    end

    context 'when the domain cannot be deleted because it still has records left' do
      before do
        allow(DomainService.new).to receive(:delete_domain).and_raise(DomainService::Errors::DomainNotEmpty)
      end

      it 'flashes an alert with the reason' do
        delete :destroy, params: { root: root }
        expect(flash.alert).to eq('Your domain could not be deleted because it contains records other than the default SOA and NS records.')
      end

      it 'redirects to the domain page' do
        delete :destroy, params: { root: root }
        expect(response).to redirect_to(domain)
      end
    end

    context 'when the domain could not be deleted for some other reason' do
      before do
        allow(DomainService.new).to receive(:delete_domain).and_return(false)
      end

      it 'flashes an alert' do
        delete :destroy, params: { root: root }
        expect(flash.alert).to eq('An unknown error occurred while trying to delete your domain.')
      end

      it 'redirects to the domain page' do
        delete :destroy, params: { root: root }
        expect(response).to redirect_to(domain)
      end
    end

    context 'when the domain does not belong to the current user' do
      let(:domain) { create(:domain) }

      it 'does not call DomainService#delete_domain' do
        expect(DomainService.new).not_to receive(:delete_domain)
        delete :destroy, params: { root: root }
      end

      it 'flashes an error message' do
        delete :destroy, params: { root: root }
        expect(flash.alert).to eq('Domain not found!')
      end

      it 'redirects to the domains list' do
        delete :destroy, params: { root: root }
        expect(response).to redirect_to(domains_path)
      end
    end

    context 'when the domain does not exist' do
      let(:root) { '.' }

      it 'flashes an error message' do
        delete :destroy, params: { root: root }
        expect(flash.alert).to eq('Domain not found!')
      end

      it 'redirects to the domain list' do
        delete :destroy, params: { root: root }
        expect(response).to redirect_to(domains_path)
      end
    end
  end

  describe '#delete' do
    it 'renders the delete confirmation page' do
      get :delete, params: { root: root }
      expect(response).to render_template(:delete)
    end
  end
end
