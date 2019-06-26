class TelegramController < ApplicationController
  skip_forgery_protection
  skip_before_action :require_login
  wrap_parameters format: []

  def create
    match = /\/(\w+)@?\w* ?(.*)/.match(message_text)
    return if match.nil?

    command, args = match[1], match[2]
    puts "command: #{command}, args: #{args}"
    return unless command == 'start'

    token = TelegramLinkToken.find_by(value: args)
    unless token.nil?
      token.user.update(telegram_user_id: telegram_user_id)
      token.delete
    end
  ensure
    head :ok
  end

  private

  def webhook_params
    params.permit(:update_id, message: [:text, {from: [:id, :first_name], chat: :id}])
  end

  def message_text
    webhook_params.dig(:message, :text)
  end

  def telegram_user_id
    webhook_params.dig(:message, :from, :id)
  end
end
