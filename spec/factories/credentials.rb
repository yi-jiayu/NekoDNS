FactoryBot.define do
  factory :credential do
    user
    name { 'ServiceRoleForNekoDNS' }
    external_id { SecureRandom.uuid }
    arn { 'arn:aws:iam::123456789012:role/ServiceRoleForNekoDNS' }
  end
end
