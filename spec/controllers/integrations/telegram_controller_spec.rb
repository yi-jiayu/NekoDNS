require 'rails_helper'

RSpec.describe Integrations::TelegramController, type: :controller do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe '#callback' do
    let(:telegram_user_id) { 123 }

    before do
      allow(TelegramService.instance).to receive(:verify_telegram_login).and_return(true)
    end

    it "sets the current user's telegram_chat_id" do
      get :callback, params: { id: telegram_user_id }
      expect(user.reload.telegram_user_id).to eq(telegram_user_id)
    end

    it 'redirects to the account page' do
      get :callback, params: { id: telegram_user_id }
      expect(response).to redirect_to(account_index_path)
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

      it 'flashes an alert and redirects to the account page' do
        get :callback, params: { id: telegram_user_id }
        expect(flash.alert).to eq('Failed to login with Telegram!')
        expect(response).to redirect_to(account_index_path)
      end

      it "does not set the user's telegram_user_id" do
        get :callback, params: { id: telegram_user_id }
        expect(user.reload.telegram_user_id).to be_nil
      end
    end
  end
end
