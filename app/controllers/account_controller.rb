class AccountController < ApplicationController
  def index
  end

  def link_telegram_account
    return redirect_to account_path unless current_user.telegram_user_id.nil?

    token = TelegramService.create_link_token(current_user)
    redirect_to telegram_deep_link(token.value)
  end

  private

  def telegram_deep_link(payload)
    "https://t.me/#{Rails.application.secrets.telegram_bot_username}?start=#{payload}"
  end
end
