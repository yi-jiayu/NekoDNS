FactoryBot.define do
  factory :domain do
    user
    root { Faker::Internet.domain_name }
  end
end
