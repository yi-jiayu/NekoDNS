FactoryBot.define do
  factory :credential do
    user
    name { 'ServiceRoleForNekoDNS' }
    arn { 'arn:aws:iam::123456789012:role/ServiceRoleForNekoDNS' }

    after :build do |credential|
      credential.generate_external_id
    end
  end
end
