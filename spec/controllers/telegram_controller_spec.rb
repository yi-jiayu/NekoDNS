require 'rails_helper'
require 'support/telegram_helpers'

RSpec.describe TelegramController, type: :controller, telegram: true do
  let(:telegram_user_id) { 123 }
  let!(:user) { create(:user, telegram_user_id: telegram_user_id) }

  before do
    request.env["HTTP_ACCEPT"] = 'application/json'
  end

  context 'list zones command' do
    context 'when the telegram_user_id is linked to a user' do
      let(:zones) { create_list(:zone, 2, user: user) }
      let(:params) { text_message(text: '/listzones', from_id: telegram_user_id, chat_id: telegram_user_id) }

      it 'renders the list zones view' do
        post :create, params: params
        expect(assigns(:chat_id)).to eq(telegram_user_id)
        expect(assigns(:zones)).to eq(zones)
        expect(subject).to render_template(:list_zones)
      end
    end

    context 'when the telegram_user_id is not linked to a user' do
      let(:params) { text_message(text: '/listzones', from_id: nil, chat_id: telegram_user_id) }

      it 'returns no content' do
        post :create, params: params
        expect(response).to have_http_status(:no_content)
      end
    end
  end

  context 'list records command' do
    context 'when the telegram_user_id is linked to a user' do
      let(:zone) { create(:zone, user: user) }
      let(:text) { "/listrecords #{zone.root}" }
      let(:params) { text_message(text: text, from_id: telegram_user_id, chat_id: telegram_user_id) }

      it 'renders the list records view' do
        post :create, params: params
        expect(assigns(:chat_id)).to eq(telegram_user_id)
        expect(assigns(:zone)).to eq(zone)
        expect(subject).to render_template(:list_records)
      end

      context 'when the user did not provide a zone' do
        let(:text) { '/listrecords' }

        it 'flashes an alert' do
          post :create, params: params
          expect(flash.alert).to eq("Please specify a zone to list records for.
Usage: `/listrecords zone_root`
Example: `/listrecords example.com`")
          expect(response).to render_template(:flash)
        end
      end

      context 'when the user does not have a zone with the given root' do
        let(:root) { 'nosuchzone' }
        let(:text) { "/listrecords #{root}" }

        it 'flashes an alert' do
          post :create, params: params
          expect(flash.alert).to eq("You don't have a zone with root `#{root}`!")
          expect(response).to render_template(:flash)
        end
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
      let(:zone) { create(:zone, user: user) }
      let(:record) { build(:record) }
      let(:text) { "/setrecord #{zone.root} #{record.type} #{record.name} #{record.value} #{record.ttl}" }
      let(:params) { text_message(text: text, from_id: telegram_user_id, chat_id: telegram_user_id) }

      before do
        allow(SetRecord).to receive(:call)
      end

      it 'calls SetRecord' do
        post :create, params: params
        expect(SetRecord).to have_received(:call).with(zone, record)
      end

      it 'renders the set record view' do
        post :create, params: params
        expect(assigns(:chat_id)).to eq(telegram_user_id)
        expect(assigns(:zone)).to eq(zone)
        expect(assigns(:record)).to eq(record)
        expect(subject).to render_template(:set_record)
      end

      context 'when not enough arguments are given' do
        let(:text) { '/setrecord' }

        it 'flashes an alert' do
          post :create, params: params
          expect(flash.alert).to eq(%q(Usage: /setrecord zone type name value TTL
Example: `/setrecord example.com A subdomain.example.com 93.184.216.34 300`))
          expect(response).to render_template(:flash)
        end
      end

      context 'when the zone is not found' do
        let(:text) { "/setrecord no_such_zone #{record.type} #{record.name} #{record.value} #{record.ttl}" }

        it 'flashes an alert' do
          post :create, params: params
          expect(flash.alert).to eq('Zone not found!')
          expect(response).to render_template(:flash)
        end
      end

      context 'when SetRecord#call raises SetRecord::RecordInvalid' do
        before do
          allow(SetRecord).to receive(:call).and_raise(SetRecord::RecordInvalid)
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
