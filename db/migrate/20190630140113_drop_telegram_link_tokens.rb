class DropTelegramLinkTokens < ActiveRecord::Migration[6.0]
  def change
    drop_table :telegram_link_tokens
  end
end
