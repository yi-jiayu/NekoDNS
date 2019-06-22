FactoryBot.define do
  factory :domain do
    user
    root { 'example.com' }

    trait :with_route53_create_hosted_zone_caller_reference do
      route53_create_hosted_zone_caller_reference { SecureRandom.uuid }
    end
  end
end
