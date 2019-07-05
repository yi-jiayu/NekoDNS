FactoryBot.define do
  factory :zone do
    user
    root { Faker::Internet.domain_name }

    trait :with_credential do
      credential
    end
  end
end
