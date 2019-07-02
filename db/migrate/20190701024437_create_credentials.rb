class CreateCredentials < ActiveRecord::Migration[6.0]
  def change
    create_table :credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :external_id, null: false
      t.string :arn, null: false

      t.timestamps
    end
  end
end
