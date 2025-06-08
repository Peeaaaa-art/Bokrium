FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    confirmed_at { Time.current }

    trait :with_line_user do
      after(:create) do |user|
        create(:line_user, user: user, line_id: "Uxxxxxxx", notifications_enabled: true)
      end
    end
  end
end
