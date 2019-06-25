require 'rails_helper'

RSpec.describe AccountController, type: :controller do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe 'GET #link_telegram_account' do
    context 'when the current user already has a Telegram user ID' do
      let(:user) { create(:user, :with_telegram_user_id) }

      it 'redirects back to the account page' do
        get :link_telegram_account
        expect(response).to redirect_to(account_path)
      end
    end
  end
end
