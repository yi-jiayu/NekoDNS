class AddIndexToDomainsRootAndUser < ActiveRecord::Migration[6.0]
  def change
    add_index :domains, [:root, :user_id]
  end
end
