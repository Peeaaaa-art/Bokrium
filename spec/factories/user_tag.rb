FactoryBot.define do
  factory :user_tag do
    name { "テストタグ" }
    color { "#6c757d" }
    association :user
  end
end
