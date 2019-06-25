FactoryBot.define do
  factory :user do
    name { Faker::Name.name }

    trait :with_telegram_user_id do
      telegram_user_id { 123 }
    end
  end
end
