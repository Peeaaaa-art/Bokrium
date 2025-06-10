# app/jobs/download_cover_image_job.rb
require "open-uri"

class DownloadCoverImageJob < ApplicationJob
  queue_as :default

  sidekiq_options lock: :until_executed, lock_timeout: 5

  def perform(book_id, image_url)
    book = Book.find_by(id: book_id)
    return unless book.present?
    return if book.book_cover_s3.attached?

    begin
      file = URI.open(image_url)
      filename = File.basename(URI.parse(image_url).path)

      book.book_cover_s3.attach(
        io: file,
        filename: filename.presence || "cover.jpg",
        content_type: file.content_type.presence || "image/jpeg",
        metadata: {
          cache_control: "public, max-age=31536000"
        }
      )

      Rails.logger.info "[DownloadCoverImageJob] 画像を保存しました：#{filename}"
    rescue => e
      Rails.logger.error "[DownloadCoverImageJob] BookID=#{book_id} 画像保存失敗: #{e.message}"
    end
  end
end
