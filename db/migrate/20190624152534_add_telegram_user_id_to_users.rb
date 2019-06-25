class AddTelegramUserIdToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :telegram_user_id, :integer
  end
end
