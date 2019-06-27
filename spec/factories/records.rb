FactoryBot.define do
  factory :record do
    name { Faker::Internet.domain_name + '.' }
    value { Faker::Internet.ip_v4_address }
    type { 'A' }
    ttl { 300 }

    trait :soa do
      value { 'sns.dns.icann.org. noc.dns.icann.org. 2019041044 7200 3600 1209600 3600' }
      type { 'SOA' }
      ttl { 900 }
    end

    trait :ns do
      sequence(:value) { |n| "ns#{n}.example.com." }
      type { 'NS' }
      ttl { 172800 }
    end
  end
end
