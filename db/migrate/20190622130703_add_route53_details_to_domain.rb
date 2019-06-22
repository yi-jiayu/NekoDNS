class AddRoute53DetailsToDomain < ActiveRecord::Migration[6.0]
  def change
    add_column :domains, :route53_create_hosted_zone_caller_reference, :string
    add_column :domains, :route53_hosted_zone_id, :string
  end
end
