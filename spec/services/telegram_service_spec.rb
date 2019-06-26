require 'rails_helper'

RSpec.describe TelegramService do
  subject { TelegramService.instance }

  describe '#create_link_token' do
    let(:user) { create(:user) }

    it 'creates a new link token with a value for a user' do
      subject.create_link_token(user)
      expect(TelegramLinkToken.find_by(user: user)).to be_present
      expect(TelegramLinkToken.find_by(user: user).value).to be_present
    end

    it 'returns the created link token' do
      token = subject.create_link_token(user)
      expect(token.reload).to eq(TelegramLinkToken.find_by(user: user))
    end

    context 'when a link token already exists for a user' do
      let!(:token) { create(:telegram_link_token, user: user) }

      it 'updates the value of the existing link token' do
        old_value = token.value
        subject.create_link_token(user)
        expect(token.reload.value).not_to eq(old_value)
      end
    end
  end

  describe '#link_telegram_account' do
    let(:user) { create(:user) }
    let(:token_value) { SecureRandom.uuid }
    let(:telegram_user_id) { 123 }

    context 'when a Telegram link token associated with the token value exists' do
      let!(:token) { create(:telegram_link_token, user: user, value: token_value) }

      it "sets the user's Telegram user ID" do
        subject.link_telegram_account(token_value, telegram_user_id)
        expect(user.reload.telegram_user_id).to eq(telegram_user_id)
      end

      it 'deletes the token' do
        subject.link_telegram_account(token_value, telegram_user_id)
        expect(TelegramLinkToken.exists?(value: token_value)).to be false
      end
    end
  end
end