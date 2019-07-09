FactoryBot.define do
  factory :import_zone_form do
    hosted_zone_id { 'OTSRAQTFHZTN' }

    trait :with_credential_id do
      transient do
        credential { create(:credential) }
      end

      credential_id { credential.id }
    end
  end
end
