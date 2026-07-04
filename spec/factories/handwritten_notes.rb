FactoryBot.define do
  factory :handwritten_note do
    data { {} }
    title { nil }
    position { 0 }
    user
    book
  end
end
