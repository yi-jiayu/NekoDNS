class CreateRecords < ActiveRecord::Migration[6.0]
  def change
    create_table :records do |t|
      t.references :domain, null: false, foreign_key: true
      t.string :name, null: false
      t.string :value, null: false
      t.string :type, null: false
      t.integer :ttl, null: false

      t.timestamps
    end
  end
end
