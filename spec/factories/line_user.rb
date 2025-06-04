FactoryBot.define do
  factory :line_user do
    association :user
    line_id { "Uxxxxxxx" }
    notifications_enabled { true }
  end
end
