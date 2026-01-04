FactoryBot.define do
  factory :credential do
    user
    sequence(:external_id) { |n| Base64.strict_encode64("credential_id_#{n}") }
    public_key { Base64.strict_encode64("fake_public_key_#{SecureRandom.hex(32)}") }
    sign_count { 0 }
    nickname { nil }

    trait :with_nickname do
      nickname { "My MacBook Pro" }
    end
  end
end
