class Integrations::TelegramController < ApplicationController
  def callback
    current_user.update(telegram_user_id: params.require(:id)) if current_user.telegram_user_id.nil?
    redirect_to account_index_path
  end
end
