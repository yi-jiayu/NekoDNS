class CreateRecords < ActiveRecord::Migration[6.0]
  def change
    create_table :records do |t|
      t.references :domain, null: false, foreign_key: true
      t.string :name
      t.string :type
      t.integer :ttl, default: 300

      t.timestamps
    end
  end
end
