require 'rails_helper'

RSpec.describe AccountController, type: :controller do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe 'GET #link_telegram_account' do
    let(:token) { create(:telegram_link_token, user: user) }

    before do
      allow(TelegramService.instance).to receive(:create_link_token).and_return(token)
    end

    it 'calls the TelegramService to create a link token' do
      expect(TelegramService.instance).to receive(:create_link_token).with(user)
      get :link_telegram_account
    end

    it 'redirects to a Telegram deep link' do
      get :link_telegram_account
      expect(response).to redirect_to("https://t.me/#{Rails.configuration.x.telegram.bot_username}?start=#{token.value}")
    end

    context 'when the current user already has a Telegram user ID' do
      let(:user) { create(:user, :with_telegram_user_id) }

      it 'redirects back to the account page' do
        get :link_telegram_account
        expect(response).to redirect_to(account_index_path)
      end
    end
  end
end
