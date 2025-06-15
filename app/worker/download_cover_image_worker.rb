require "open-uri"

class DownloadCoverImageWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, lock: :until_executed, lock_timeout: 5

  def perform(book_id, image_url)
    Rails.logger.info "🐛 Worker triggered with book_id=#{book_id}, url=#{image_url}"
    book = Book.find_by(id: book_id)
    return unless book.present?
    return if book.book_cover_s3.attached?

    return if $redis.exists?("cdl:fail:#{book_id}")

    redis_key = "cdl:#{book_id}" # "cdl" = cover download
    return if $redis.exists?(redis_key)
    $redis.set(redis_key, "working", ex: 300)

    begin
      file = URI.open(image_url, "User-Agent" => "Mozilla/5.0")
      Rails.logger.info "📦 Content-Type: #{file.content_type}"
      Rails.logger.info "📏 File Size: #{file.size}"
      parsed = URI.parse(image_url)
      filename = File.basename(parsed.path).presence || "cover.jpg"
      content_type = file.content_type.presence || "image/jpeg"

      book.book_cover_s3.attach(
        io: file,
        filename: filename,
        content_type: content_type,
        metadata: {
          cache_control: "public, max-age=31536000"
        }
      )

      Rails.logger.info "✅[DownloadCoverImageWorker] 画像を保存しました：#{filename} (#{content_type})"
      book.reload
      unless book.book_cover_s3.attached?
        Rails.logger.warn "⬜️[DownloadCoverImageWorker] 添付に失敗しました（book_id=#{book.id})"
        $redis.set("cdl:fail:#{book_id}", "1", ex: 600)
      end
    rescue => e
      Rails.logger.error "⚪️[DownloadCoverImageWorker] BookID=#{book_id} 画像保存失敗: #{e.class} - #{e.message}"
      $redis.set("cdl:fail:#{book_id}", "1", ex: 600)
    ensure
      $redis.del(redis_key)
    end
  end
end
