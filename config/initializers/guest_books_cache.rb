Rails.application.config.after_initialize do
  if Rails.env.production?
    begin
      guest_user = User.find_by(email: ENV["GUEST_USER_EMAIL"])

      if guest_user.present?
        Rails.cache.fetch("guest_sample_books", expires_in: nil) do
          guest_user.books
            .includes(book_cover_s3_attachment: :blob)
            .order(created_at: :desc)
            .to_a
        end
      else
        Rails.logger.warn("[GuestBooksCache] ゲストユーザーが見つかりませんでした")
      end
    rescue ActiveRecord::NoDatabaseError, PG::ConnectionBad, ActiveRecord::ConnectionNotEstablished => e
      Rails.logger.warn("[GuestBooksCache] DBに接続できなかったためキャッシュをスキップ: #{e.class} #{e.message}")
    end
  end
end
