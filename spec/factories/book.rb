# spec/factories/books.rb
FactoryBot.define do
  factory :book do
    title { "サンプルタイトル" }
    sequence(:isbn) { |n| "9781234567#{format('%03d', n)}" }
    publisher { "出版社名" }
    page { 300 }
    author { "著者名" }
    price { 1500 }
    status { :want_to_read }
    association :user
  end
end
