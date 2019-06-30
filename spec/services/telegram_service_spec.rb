# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TelegramService do
  subject(:telegram_service) { described_class.instance }

  describe '#verify_telegram_login' do
    let(:params) do
      { id: '123',
        first_name: 'first_name',
        username: 'username',
        auth_date: '1561898119',
        hash: 'e6ff35208039c53f10962731498da6ca7fb40d541819a8f9cc8046b2f9c2d812' }
    end
    let(:token) { 'bot_token' }

    context 'when the data received is authentic' do
      it 'returns true' do
        expect(telegram_service.verify_telegram_login(params, token)).to be true
      end

      context 'when params uses string instead of symbol keys' do
        it 'returns true' do
          expect(telegram_service.verify_telegram_login(params.stringify_keys, token)).to be true
        end
      end
    end

    context 'when the data received is not authentic' do
      let(:token) { 'bot_token_2' }

      it 'returns false' do
        expect(telegram_service.verify_telegram_login(params, token)).to be false
      end
    end
  end
end
