FactoryBot.define do
  factory :book_tag_assignment do
    association :book
    association :user_tag
    association :user
  end
end
