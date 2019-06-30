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

      context 'when not enough arguments are given' do
        let(:text) { '/setrecord' }

        it 'flashes an alert' do
          post :create, params: params
          expect(flash.alert).to eq(%q(Usage: /setrecord domain type name value TTL
Example: `/setrecord example.com A subdomain.example.com 93.184.216.34 300`))
          expect(response).to render_template(:flash)
        end
      end

      context 'when the domain is not found' do
        let(:text) { "/setrecord no_such_domain #{record.type} #{record.name} #{record.value} #{record.ttl}" }

        it 'flashes an alert' do
          post :create, params: params
          expect(flash.alert).to eq('Domain not found!')
          expect(response).to render_template(:flash)
        end
      end

      context 'when DomainService#set_record raises DomainService::Errors::RecordInvalid' do
        before do
          allow(DomainService.instance).to receive(:set_record).and_raise(DomainService::Errors::RecordInvalid)
        end

        it 'flashes an alert' do
          post :create, params: params
          expect(flash.alert).to eq('The record you specified was invalid!')
          expect(response).to render_template(:flash)
        end
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
