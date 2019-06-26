class TelegramController < ApplicationController
  skip_forgery_protection
  skip_before_action :require_login
  wrap_parameters format: []

  def create
    command, args = command_and_args
    case command
    when 'start'
      TelegramService.instance.link_telegram_account(args, telegram_user_id)
    end
  ensure
    head :ok
  end

  private

  def update_params
    params.permit(:update_id, message: [:text, { from: [:id, :first_name], chat: :id }])
  end

  def message_text
    update_params.dig(:message, :text)
  end

  def telegram_user_id
    update_params.dig(:message, :from, :id)&.to_i
  end

  def command_and_args
    match = /\/(\w+)@?\w* ?(.*)/.match(message_text)
    return if match.nil?

    [match[1], match[2]]
  end
end
