require 'rails_helper'
require 'support/telegram_helpers'

RSpec.describe TelegramController, type: :controller, telegram: true do
  # Telegram will keep trying to deliver the update if we do not return a successful status.
  after do
    expect(response).to be_successful
  end

  describe 'POST #create' do
    context 'start command with link token' do
      let(:token_value) { SecureRandom.uuid }
      let(:telegram_user_id) { 123 }
      let(:params) { text_message(text: "/start #{token_value}", from_id: telegram_user_id) }

      it 'calls #link_telegram_account on the TelegramService instance' do
        expect(TelegramService.instance).to receive(:link_telegram_account).with(token_value, telegram_user_id)
        post :create, params: params
      end
    end
  end
end
