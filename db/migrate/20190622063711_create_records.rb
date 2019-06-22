class CreateRecords < ActiveRecord::Migration[6.0]
  def change
    create_table :records do |t|
      t.references :domain, null: false, foreign_key: true
      t.string :name
      t.string :type
      t.integer :ttl

      t.timestamps
    end
  end
end
