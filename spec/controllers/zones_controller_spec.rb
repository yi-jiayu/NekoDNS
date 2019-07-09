# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ZonesController, type: :controller do
  let(:user) { create(:user) }
  let(:zone) { create(:zone, user: user) }
  let(:root) { zone.root }

  before do
    login_as(user)
  end

  describe '#create' do
    let(:params) { { root: root } }

    before do
      allow(CreateZone).to receive(:call).and_return(zone)
    end

    context 'when creating a managed zone' do
      let(:params) { { root: root, managed: 'true' } }

      it 'calls CreateZone with nil for credential' do
        post :create, params: params
        expect(CreateZone).to have_received(:call).with(user, root, nil)
      end

      context 'when the :managed_zones feature is not enabled' do
        before do
          allow(Features).to receive(:enabled?).with(:managed_zones).and_return(false)
        end

        it 'flashes an alert' do
          post :create, params: params
          expect(flash.alert).to eq('Managed zones are currently not enabled!')
        end

        it 'renders :new' do
          post :create, params: params
          expect(response).to render_template(:new)
        end
      end
    end

    context 'when creating a zone using user credentials' do
      let(:credential) { create(:credential, user: user) }
      let(:params) { { root: root, managed: 'false', credential_id: credential.id.to_s } }

      it 'calls CreateZone with the provided credential' do
        post :create, params: params
        expect(CreateZone).to have_received(:call).with(user, root, credential)
      end

      context 'when params[:credential_id] is not present' do
        let(:params) { { root: 'example.com', managed: 'false' } }

        it 'flashes an alert' do
          post :create, params: params
          expect(flash.alert).to eq('You must specify a credential to use when creating an unmanaged zone.')
        end

        it 'renders :new' do
          post :create, params: params
          expect(response).to render_template(:new)
        end
      end

      context 'when the credential specified by params[:credential_id] does not exist' do
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
        before do
          allow(CreateZone).to receive(:call).and_raise(Credential::AccessDenied)
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

    it 'redirects to the zone page' do
      post :create, params: params
      expect(response).to redirect_to(zone)
    end

    context 'when the provided zone root contains a trailing dot' do
      let(:root) { 'example.com.' }

      it 'removes it before calling CreateZone' do
        expect(CreateZone).to receive(:call).with(user, 'example.com', anything)
        post :create, params: params
      end
    end

    context 'when CreateZone#call raises CreateZone::ZoneAlreadyExists' do
      before do
        allow(CreateZone).to receive(:call).and_raise(CreateZone::ZoneAlreadyExists)
      end

      it 'flashes an alert and redirects back to new' do
        post :create, params: params
        expect(flash.alert).to eq('You have already created a zone with that root!')
        expect(response).to redirect_to(new_zone_path)
      end
    end
  end

  describe '#new_import' do
    it 'renders :new_import' do
      get :new_import
      expect(response).to render_template(:new_import)
    end
  end

  describe '#create_import' do
    let(:credential) { create(:credential, user: user) }

    let(:hosted_zone_id) { 'OTSRAQTFHZTN' }
    let(:import_zone_params) { { hosted_zone_id: hosted_zone_id, credential_id: credential.id.to_s } }
    let(:form) { ImportZoneForm.new(import_zone_params) }
    let(:params) { { import_zone_form: import_zone_params } }
    let(:zone) { create(:zone) }

    before do
      allow(ImportZoneForm).to receive(:new).and_return(form)
      allow(form).to receive(:valid?).and_return(true)
      allow(ImportZone).to receive(:call).and_return(zone)
    end

    it 'validates parameters' do
      post :create_import, params: params
      expect(ImportZoneForm).to have_received(:new).with(permitted_params(import_zone_params))
      expect(form).to have_received(:valid?)
    end

    it 'calls ImportZone' do
      post :create_import, params: params
      expect(ImportZone).to have_received(:call).with(user, hosted_zone_id, credential)
    end

    it 'redirects to the imported zone' do
      post :create_import, params: params
      expect(response).to redirect_to(zone)
    end

    context 'when params are invalid' do
      before do
        allow(form).to receive(:valid?).and_return(false)
      end

      it 'renders :new_import' do
        post :create_import, params: params
        expect(response).to render_template(:new_import)
      end
    end

    context 'when the credentials do not have access' do
      before do
        allow(ImportZone).to receive(:call).and_raise(Credential::AccessDenied)
      end

      it 'flashes an alert' do
        post :create_import, params: params
        expect(flash.alert).to eq('The credentials you specified do not have the right permissions to import this zone.')
      end

      it 'renders :new_import' do
        post :create_import, params: params
        expect(response).to render_template(:new_import)
      end
    end

    context 'when the hosted zone ID does not exist' do
      before do
        allow(ImportZone).to receive(:call).and_raise(ImportZone::NoSuchHostedZone)
      end

      it 'flashes an alert' do
        post :create_import, params: params
        expect(flash.alert).to eq('No such hosted zone!')
      end

      it 'renders :new_import' do
        post :create_import, params: params
        expect(response).to render_template(:new_import)
      end
    end
  end

  describe '#destroy' do
    before do
      allow(DeleteZone).to receive(:call).and_return(true)
    end

    it 'calls DeleteZone' do
      delete :destroy, params: { root: root }
      expect(DeleteZone).to have_received(:call).with(zone)
    end

    it 'flashes a notice that the zone was deleted' do
      delete :destroy, params: { root: root }
      expect(flash.notice).to eq('Zone deleted!')
    end

    it 'redirects to the zones list' do
      delete :destroy, params: { root: root }
      expect(response).to redirect_to(zones_path)
    end

    context 'when the zone cannot be deleted because it still has records left' do
      before do
        allow(DeleteZone).to receive(:call).and_raise(DeleteZone::ZoneNotEmpty)
      end

      it 'flashes an alert with the reason' do
        delete :destroy, params: { root: root }
        expect(flash.alert).to eq('Your zone could not be deleted because it contains records other than the default SOA and NS records.')
      end

      it 'redirects to the zone page' do
        delete :destroy, params: { root: root }
        expect(response).to redirect_to(zone)
      end
    end

    context 'when the zone could not be deleted for some other reason' do
      before do
        allow(DeleteZone).to receive(:call).and_return(false)
      end

      it 'flashes an alert' do
        delete :destroy, params: { root: root }
        expect(flash.alert).to eq('An unknown error occurred while trying to delete your zone.')
      end

      it 'redirects to the zone page' do
        delete :destroy, params: { root: root }
        expect(response).to redirect_to(zone)
      end
    end

    context 'when the zone does not belong to the current user' do
      let(:zone) { create(:zone) }

      before do
        allow(DeleteZone).to receive(:call)
      end

      it 'does not call DeleteZone' do
        delete :destroy, params: { root: root }
        expect(DeleteZone).not_to have_received(:call)
      end

      it 'flashes an error message' do
        delete :destroy, params: { root: root }
        expect(flash.alert).to eq('Zone not found!')
      end

      it 'redirects to the zones list' do
        delete :destroy, params: { root: root }
        expect(response).to redirect_to(zones_path)
      end
    end

    context 'when the zone does not exist' do
      let(:root) { '.' }

      it 'flashes an error message' do
        delete :destroy, params: { root: root }
        expect(flash.alert).to eq('Zone not found!')
      end

      it 'redirects to the zone list' do
        delete :destroy, params: { root: root }
        expect(response).to redirect_to(zones_path)
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
