FactoryBot.define do
  factory :domain do
    user
    root { 'example.com' }
  end
end
