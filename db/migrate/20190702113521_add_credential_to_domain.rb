class AddCredentialToDomain < ActiveRecord::Migration[6.0]
  def change
    add_reference :domains, :credential, foreign_key: true
  end
end
