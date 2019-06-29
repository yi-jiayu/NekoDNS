Rails.application.configure do
  config.x.telegram.bot_username = ENV['TELEGRAM_BOT_USERNAME']
  config.x.telegram.bot_token = ENV['TELEGRAM_BOT_TOKEN']
end