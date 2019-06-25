class CreateTelegramLinkTokens < ActiveRecord::Migration[6.0]
  def change
    create_table :telegram_link_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :value

      t.timestamps
    end
  end
end
