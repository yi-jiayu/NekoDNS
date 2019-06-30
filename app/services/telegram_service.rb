class TelegramService
  include Singleton

  def verify_telegram_login(params, token)
    params = params.symbolize_keys
    data = params.except(:hash).sort.map { |k, v| "#{k}=#{v}" }.join("\n")
    key = Digest::SHA256.digest(token)
    mac = OpenSSL::HMAC.hexdigest('SHA256', key, data)
    params[:hash] == mac
  end
end