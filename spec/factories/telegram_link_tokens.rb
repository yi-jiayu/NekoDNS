FactoryBot.define do
  factory :telegram_link_token do
    value { SecureRandom.uuid }
  end
end
