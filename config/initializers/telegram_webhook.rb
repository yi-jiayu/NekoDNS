# Sets the bot's Telegram webhook URL to the ngrok endpoint for the application

if Rails.env.development? && defined?(Rails::Server)
  Rails.application.configure do
    config.after_initialize do
      if Rails.configuration.respond_to?(:ngrok_host) && Rails.configuration.ngrok_host.present?
        ngrok_host = Rails.configuration.ngrok_host
        puts "initializers/telegram_webhook.rb: config.ngrok_host detected: #{ngrok_host}"
        webhook_url = URI::HTTPS.build(host: ngrok_host, path: '/telegram/updates').to_s
        puts "initializers/telegram_webhook.rb: setting Telegram bot webhook URL to #{webhook_url}"
        set_webhook_endpoint = URI::HTTPS.build(host: 'api.telegram.org', path: "/bot#{Rails.application.secrets.telegram_bot_token}/setWebhook")
        res = Net::HTTP.post_form(set_webhook_endpoint, 'url' => webhook_url)
        puts "initializers/telegram_webhook.rb: #{res.body}"
      end
    end
  end
end