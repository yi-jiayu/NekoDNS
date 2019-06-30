require 'rails_helper'

RSpec.describe Integrations::TelegramController, type: :controller do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe '#callback' do
    let(:telegram_user_id) { 123 }
    let(:params) { { 'id' => telegram_user_id.to_s } }
    let(:bot_token) { 'bot_token' }

    before do
      allow(TelegramService.instance).to receive(:verify_telegram_login).and_return(true)
      allow(Rails.configuration.x.telegram).to receive(:bot_token).and_return(bot_token)
    end

    it "sets the current user's telegram_chat_id" do
      get :callback, params: params
      expect(user.reload.telegram_user_id).to eq(telegram_user_id)
    end

    it 'redirects to the account page' do
      get :callback, params: params
      expect(response).to redirect_to(account_index_path)
    end

    it 'calls TelegramService#verify_telegram_login to check the received params' do
      expect(TelegramService.instance).to receive(:verify_telegram_login).with(params, bot_token)
      get :callback, params: params
    end

    context "when the user's telegram_user_id is already set" do
      let(:user) { create(:user, telegram_user_id: telegram_user_id) }

      it 'does not set it again' do
        get :callback, params: { id: telegram_user_id + 1 }
        expect(user.reload.telegram_user_id).to eq(telegram_user_id)
      end
    end

    context 'when the params cannot be verified' do
      before do
        allow(TelegramService.instance).to receive(:verify_telegram_login).and_return(false)
      end

      it 'flashes an alert' do
        get :callback, params: params
        expect(flash.alert).to eq('Failed to login with Telegram!')
      end

      it 'redirects to the account page' do
        get :callback, params: params
        expect(response).to redirect_to(account_index_path)
      end

      it "does not set the user's telegram_user_id" do
        get :callback, params: params
        expect(user.reload.telegram_user_id).to be_nil
      end
    end
  end

  describe '#destroy' do
    let(:user) { create(:user, :with_telegram_user_id) }

    it "removes the user's telegram_user_id" do
      delete :destroy
      expect(user.reload.telegram_user_id).to be_nil
    end

    it 'flashes a notice' do
      delete :destroy
      expect(flash.notice).to eq('Telegram account unlinked!')
    end

    it 'redirects to the account page' do
      delete :destroy
      expect(response).to redirect_to(account_index_path)
    end
  end
end
