module GuestUserHelper
  def ensure_guest_user
    guest_email = ENV["GUEST_USER_EMAIL"].presence || "guest@example.com"

    user = User.find_or_create_by!(email: guest_email) do |u|
      u.password = 'password'
      u.confirmed_at = Time.current
    end

    user.books.find_or_create_by!(isbn: "9781001001001") do |book|
      book.title = "スターター本"
      book.author = "ゲスト著者"
    end

    user
  end
end
