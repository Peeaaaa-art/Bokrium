module BookApis
  class GoogleBooksService
    require "net/http"
    require "uri"
    require "json"

    ENDPOINT = "https://www.googleapis.com/books/v1/volumes"

    def self.fetch(isbn)
      return nil if isbn.blank?

      uri = URI.parse("#{ENDPOINT}?q=isbn:#{URI.encode_www_form_component(isbn)}")
      response = Net::HTTP.get_response(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      parse_response(JSON.parse(response.body), isbn)
    rescue StandardError => e
      Rails.logger.error("[GoogleBooksService][ISBN] #{e.message}")
      nil
    end

    def self.fetch_by_title_or_author(query, page = 1)
      return blank_result if query.blank?

      uri = URI.parse("#{ENDPOINT}?" + URI.encode_www_form({
        q: query,
        maxResults: 30,
        startIndex: (page - 1) * 30
      }))

      response = Net::HTTP.get_response(uri)
      return blank_result unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      {
        items: parse_multiple(data),
        total_count: data["totalItems"].to_i
      }
    rescue StandardError => e
      Rails.logger.error("[GoogleBooksService][Title/Author] #{e.message}")
      blank_result
    end

    private

    def self.parse_response(data, isbn)
      item = data["items"]&.first
      return nil unless item

      volume_info = item["volumeInfo"] || {}
      {
        isbn: isbn,
        price: nil,
        title: volume_info["title"],
        author: Array(volume_info["authors"]).join(", "),
        publisher: volume_info["publisher"],
        book_cover: https_image(volume_info.dig("imageLinks", "thumbnail")),
        page: volume_info["pageCount"]&.to_i
      }
    end

    def self.parse_multiple(data)
      return [] unless data["items"].is_a?(Array)

      data["items"].map do |item|
        volume_info = item["volumeInfo"] || {}
        {
          title: volume_info["title"],
          author: Array(volume_info["authors"]).join(", "),
          publisher: volume_info["publisher"],
          isbn: volume_info["industryIdentifiers"]&.find { |id| id["type"].include?("ISBN") }&.dig("identifier"),
          price: nil,
          book_cover: https_image(volume_info.dig("imageLinks", "thumbnail"))
        }
      end
    end

    def self.https_image(url)
      url&.gsub(/^http:\/\//, "https://")
    end

    def self.blank_result
      { items: [], total_count: 0 }
    end
  end
end