def ensure_guest_user
  guest_email = ENV["GUEST_USER_EMAIL"] || 'bokrium+guest@gmail.com'

  user = User.find_by(email: guest_email)

  unless user
    user = User.create!(
      email: guest_email,
      password: 'password',
      confirmed_at: Time.current
    )

  end

  if user.books.where(isbn: "9781001001001").blank?
    user.books.create!(
      title: "スターター本",
      author: "ゲスト著者",
      isbn: "9781001001001",
    )
  end

  user
end
