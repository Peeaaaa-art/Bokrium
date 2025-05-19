# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# ゲストユーザー（存在しなければ作る）
guest_user = User.find_or_create_by!(id: 999) do |user|
  user.email = "guest@example.com"
  user.password = "jfds!lk@@fdsjkKINOWAYNkfdjj_fdajfda-fdaskjdfsa"
  user.name = "ゲストユーザー"
end

# ゲスト用の書籍
12.times do |i|
  book = guest_user.books.create!(
    title: "ゲストサンプル本 #{i + 1}",
    author: "著者 #{i + 1}",
    isbn: "9781234567#{100 + i}",
    page: rand(100..300),
    price: rand(500..2000)
  )

  book.memos.create!(
    user_id: guest_user.id,
    content: "<p>これはゲスト用のメモです。</p>"
  )
end