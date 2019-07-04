FactoryBot.define do
  factory :domain do
    user
    root { Faker::Internet.domain_name }

    trait :with_credential do
      credential
    end
  end
end
