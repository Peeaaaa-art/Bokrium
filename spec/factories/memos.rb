FactoryBot.define do
  factory :memo do
    content { "テストメモ" }
    visibility { Memo::VISIBILITY[:only_me] }
    user
    book
  end
end