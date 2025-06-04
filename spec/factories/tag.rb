FactoryBot.define do
  factory :tag, class: 'ActsAsTaggableOn::Tag' do
    name { "テストタグ" }
    association :user  # 必須
  end
end
