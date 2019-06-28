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
  end

  context 'list domains command' do
    context 'when the telegram_user_id is linked to a user' do
      let!(:user) { create(:user, telegram_user_id: telegram_user_id) }
      let(:domains) { create_list(:domain, 2, user: user) }
      let(:params) { text_message(text: '/listdomains', from_id: telegram_user_id, chat_id: telegram_user_id) }

      it 'renders the list domains view' do
        post :create, params: params
        expect(assigns(:chat_id)).to eq(telegram_user_id)
        expect(assigns(:domains)).to eq(domains)
        expect(subject).to render_template(:list_domains)
      end
    end

    context 'when the telegram_user_id is not linked to a user' do
      let(:params) { text_message(text: '/listdomains', from_id: nil, chat_id: telegram_user_id) }

      it 'returns no content' do
        post :create, params: params
        expect(response).to have_http_status(:no_content)
      end
    end
  end

  context 'list records command' do
    context 'when the telegram_user_id is linked to a user' do
      let(:user) { create(:user, telegram_user_id: telegram_user_id) }
      let(:domain) { create(:domain, user: user) }
      let(:params) { text_message(text: "/listrecords #{domain.root}", from_id: telegram_user_id, chat_id: telegram_user_id) }

      it 'renders the list records view' do
        post :create, params: params
        expect(assigns(:chat_id)).to eq(telegram_user_id)
        expect(assigns(:domain)).to eq(domain)
        expect(subject).to render_template(:list_records)
      end
    end

    context 'when the telegram_user_id is not linked to a user' do
      let(:params) { text_message(text: '/listrecords', from_id: nil, chat_id: telegram_user_id) }

      it 'returns no content' do
        post :create, params: params
        expect(response).to have_http_status(:no_content)
      end
    end
  end

  context 'set record command' do
    context 'when the telegram_user_id is linked to a user' do
      let!(:user) { create(:user, telegram_user_id: telegram_user_id) }
      let(:domain) { create(:domain, user: user) }
      let(:record) { build(:record) }
      let(:text) { "/setrecord #{domain.root} #{record.type} #{record.name} #{record.value} #{record.ttl}" }
      let(:params) { text_message(text: text, from_id: telegram_user_id, chat_id: telegram_user_id) }

      before do
        allow(DomainService.instance).to receive(:set_record)
      end

      it 'calls DomainService#set_record' do
        expect(DomainService.instance).to receive(:set_record).with(domain, record)
        post :create, params: params
      end

      it 'renders the set record view' do
        post :create, params: params
        expect(assigns(:chat_id)).to eq(telegram_user_id)
        expect(assigns(:domain)).to eq(domain)
        expect(assigns(:record)).to eq(record)
        expect(subject).to render_template(:set_record)
      end
    end

    context 'when the telegram_user_id is not linked to a user' do
      let(:params) { text_message(text: '/setrecord', from_id: nil, chat_id: telegram_user_id) }

      it 'returns no content' do
        post :create, params: params
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
