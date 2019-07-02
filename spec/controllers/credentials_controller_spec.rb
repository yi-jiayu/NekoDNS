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
    it 'sets aws_external_id on the session' do
      get :new
      expect(session[:aws_external_id]).to be_present
    end
  end

  describe '#create' do
    let(:credential) { create(:credential, user: user) }
    let(:params) { { credential: { name: credential.name, arn: credential.arn } } }

    before do
      request.session[:aws_external_id] = credential.external_id
      allow(Credential).to receive(:create).and_return(credential)
    end

    it 'creates a new credential from the current user, params and session' do
      post :create, params: params
      expect(Credential).to have_received(:create).with(user: user,
                                                        name: params[:credential][:name],
                                                        arn: params[:credential][:arn],
                                                        external_id: request.session[:aws_external_id])
    end

    context 'when the params are invalid' do
      let(:params) { { credential: { name: '', arn: '' } } }

      before do
        allow(Credential).to receive(:create).and_call_original
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
