class GoogleBooksService
  require "net/http"
  require "uri"
  require "json"

  ENDPOINT = "https://www.googleapis.com/books/v1/volumes"

  def self.fetch(isbn)
    uri = URI.parse("#{ENDPOINT}?q=isbn:#{isbn}")
    response = Net::HTTP.get_response(uri)

    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    item = data["items"]&.first
    return nil unless item

    volume_info = item["volumeInfo"]

    {
      isbn: isbn,
      price: nil,
      title:        volume_info["title"],
      author: Array(volume_info["authors"]).join(", "),
      publisher:    volume_info["publisher"],
      book_cover:   volume_info.dig("imageLinks", "thumbnail"),
      page:         volume_info["pageCount"]&.to_i
    }
  rescue StandardError => e
    Rails.logger.error("[GoogleBooksService] #{e.message}")
    nil
  end
end
