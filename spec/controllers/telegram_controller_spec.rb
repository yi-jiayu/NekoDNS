require 'rails_helper'
require 'support/telegram_helpers'

RSpec.describe TelegramController, type: :controller, telegram: true do
  let(:telegram_user_id) { 123 }

  before do
    request.env["HTTP_ACCEPT"] = 'application/json'
  end

  # Telegram will keep trying to deliver the update if we do not return a successful status.
  after do
    expect(response).to be_successful
  end

  describe 'POST #create' do
    context 'start command with link token' do
      let(:token_value) { SecureRandom.uuid }
      let(:params) { text_message(text: "/start #{token_value}", from_id: telegram_user_id) }

      it 'calls #link_telegram_account on the TelegramService instance' do
        expect(TelegramService.instance).to receive(:link_telegram_account).with(token_value, telegram_user_id)
        post :create, params: params
      end
    end

    context 'list domains command' do
      context 'when the telegram_user_id is linked to a user' do
        let!(:user) { create(:user, telegram_user_id: telegram_user_id) }
        let(:domains) { create_list(:domain, 2, user: user) }
        let(:params) { text_message(text: '/listdomains', from_id: telegram_user_id, chat_id: telegram_user_id) }

        it 'renders a Telegram bot API sendMessage request' do
          post :create, params: params
          expect(assigns(:chat_id)).to eq(telegram_user_id)
          expect(assigns(:domains)).to eq(domains)
          expect(subject).to render_template(:send_message)
        end
      end
    end
  end
end
