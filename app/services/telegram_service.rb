class TelegramService
  class << self
    def create_link_token(user)
      token = TelegramLinkToken.find_or_create_by(user: user)
      token.update(value: SecureRandom.uuid)
      token
    end
  end
end