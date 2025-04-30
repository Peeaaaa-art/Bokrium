class GoogleBooksService
  require "net/http"
  require "uri"
  require "json"

  ENDPOINT = "https://www.googleapis.com/books/v1/volumes"

  def self.fetch(isbn)
    uri = URI.parse("#{ENDPOINT}?q=isbn:#{isbn}")
    response = Net::HTTP.get_response(uri)

    return nil unless response.is_a?(Net::HTTPSuccess)

    parse_response(response.body, isbn)
  rescue StandardError => e
    Rails.logger.error("[GoogleBooksService][ISBN] #{e.message}")
    nil
  end

  def self.fetch_by_title_or_author(query, page = 1)
    per_page = 30
    start_index = (page - 1) * per_page

    uri = URI.parse("#{ENDPOINT}?q=#{URI.encode_www_form_component(query)}&maxResults=#{per_page}&startIndex=#{start_index}")
    response = Net::HTTP.get_response(uri)

    return { items: [], total_count: 0 } unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    {
      items: parse_multiple(data),
      total_count: data["totalItems"].to_i
    }
  rescue StandardError => e
    Rails.logger.error("[GoogleBooksService][Title/Author] #{e.message}")
    { items: [], total_count: 0 }
  end

  private

  def self.parse_response(body, isbn)
    data = JSON.parse(body)
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
  end

  def self.parse_multiple(data)
    return [] unless data["items"]

    data["items"].map do |item|
      volume_info = item["volumeInfo"]

      {
        title: volume_info["title"],
        author: Array(volume_info["authors"]).join(", "),
        publisher: volume_info["publisher"],
        isbn: volume_info["industryIdentifiers"]&.find { |id| id["type"].include?("ISBN") }&.dig("identifier"),
        price: nil,
        book_cover: volume_info.dig("imageLinks", "thumbnail")
      }
    end
  end
end
