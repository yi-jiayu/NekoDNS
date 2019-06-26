class TelegramService
  include Singleton

  def create_link_token(user)
    token = TelegramLinkToken.find_or_create_by(user: user)
    token.update(value: SecureRandom.uuid)
    token
  end

  def link_telegram_account(token_value, telegram_user_id)
    token = TelegramLinkToken.find_by(value: token_value)
    unless token.nil?
      token.user.update(telegram_user_id: telegram_user_id)
      token.delete
    end
  end
end