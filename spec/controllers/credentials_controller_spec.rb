require 'rails_helper'

RSpec.describe CredentialsController, type: :controller do
  let(:user) { create(:user) }
  let(:credentials) { create_list(:credential, 2, user: user) }

  before do
    login_as(user)
  end

  describe '#index' do
    it 'assigns @credentials' do
      get :index
      expect(assigns(:credentials)).to eq(credentials)
    end
  end

  describe '#new' do
    let(:credential) { build(:credential) }

    before do
      allow(Credential).to receive(:new).and_return(credential)
      allow(credential).to receive(:generate_external_id)
    end

    it 'sets @credential' do
      get :new
      expect(assigns(:credential)).to eq(credential)
    end

    it "generates the credential's external ID" do
      get :new
      expect(credential).to have_received(:generate_external_id)
    end
  end

  describe '#create' do
    let(:credential) { build(:credential, user: user) }
    let(:params) { { credential: { name: credential.name,
                                   external_id: credential.external_id,
                                   signed_external_id: credential.signed_external_id,
                                   arn: credential.arn } } }

    it 'saves a new credential' do
      expect { post :create, params: params }.to change { Credential.count }.by(1)
    end

    it 'redirects to the credential page' do
      post :create, params: params
      expect(response).to redirect_to(Credential.last)
    end

    context 'when the params are invalid' do
      let(:params) { { credential: { name: '', arn: '' } } }

      before do
        allow(Credential).to receive(:new).and_call_original
      end

      it 'does not save the credential' do
        expect { post :create, params: params }.not_to change { Credential.count }
      end

      it 'renders the new page' do
        post :create, params: params
        expect(response).to render_template(:new)
      end
    end
  end

  describe '#show' do
    let(:credential) { create(:credential, user: user) }

    it 'assigns @credential' do
      get :show, params: { id: credential.id }
      expect(assigns(:credential)).to eq(credential)
    end
  end
end
