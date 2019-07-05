class RenameDomainToZone < ActiveRecord::Migration[6.0]
  def change
    rename_table :domains, :zones
  end
end
