require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  describe '#create' do
    context 'when the user already exists' do
      let(:user) { create(:user, provider: 'github', uid: '123') }
      let(:omniauth_hash) { { 'provider' => user.provider, 'uid' => user.uid } }

      before do
        request.env['omniauth.auth'] = omniauth_hash
      end

      it 'sets session[:user_id]' do
        get :create, params: { provider: 'github' }
        expect(request.session[:user_id]).to eq(user.id)
      end

      it 'resets the session' do
        expect(controller).to receive(:reset_session)
        get :create, params: { provider: 'github' }
      end
    end
  end

  describe '#destroy' do
    before do
      request.session[:user_id] = 123
    end

    it 'unsets session[:user_id]' do
      get :destroy
      expect(request.session[:user_id]).not_to be_present
    end

    it 'resets the session' do
      expect(controller).to receive(:reset_session)
      get :destroy
    end
  end
end
