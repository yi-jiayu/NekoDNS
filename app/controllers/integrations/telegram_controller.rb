class Integrations::TelegramController < ApplicationController
  def callback
    unless TelegramService.instance.verify_telegram_login(callback_params.to_h, Rails.configuration.x.telegram.bot_token)
      flash.alert = 'Failed to login with Telegram!'
      return redirect_to account_index_path
    end

    user_id = callback_params.require(:id)
    current_user.update(telegram_user_id: user_id) if current_user.telegram_user_id.nil?
    redirect_to account_index_path
  end

  def destroy
    current_user.update(telegram_user_id: nil)
    flash.notice = 'Telegram account unlinked!'
    redirect_to account_index_path
  end

  private

  def callback_params
    params.permit(:id, :first_name, :username, :photo_url, :auth_date, :hash)
  end
end
