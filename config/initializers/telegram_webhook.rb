# Sets the bot's Telegram webhook URL to the ngrok endpoint for the application

Rails.application.configure do
  return if Rails.env.test?

  config.after_initialize do
    if Rails.configuration.ngrok_host.present?
      webhook_url = URI::HTTPS.build(host: Rails.configuration.ngrok_host, path: '/telegram/updates').to_s
      Rails.logger.info "Setting Telegram webhook URL to #{webhook_url}"
      set_webhook_endpoint = URI::HTTPS.build(host: 'api.telegram.org', path: "/bot#{Rails.application.secrets.telegram_bot_token}/setWebhook")
      res = Net::HTTP.post_form(set_webhook_endpoint, 'url' => webhook_url)
      puts res.body
    end
  end
end