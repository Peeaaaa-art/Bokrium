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

      with_isbn = []
      without_isbn = []

      data["items"].each do |item|
        volume_info = item["volumeInfo"] || {}
        identifiers = volume_info["industryIdentifiers"]
        isbn = extract_isbn(identifiers)

        book_data = {
          title: volume_info["title"],
          author: Array(volume_info["authors"]).join(", "),
          publisher: volume_info["publisher"],
          isbn: isbn,
          price: nil,
          book_cover: https_image(volume_info.dig("imageLinks", "thumbnail"))
        }

        if isbn.present?
          with_isbn << book_data
        else
          without_isbn << book_data
        end
      end

      # ISBN ありを先に、足りないぶんだけ ISBN なしで補完
      (with_isbn + without_isbn).take(30)
    end
    def self.extract_isbn(identifiers)
      identifiers ||= []
      identifiers.find { |id| id["type"] == "ISBN_13" }&.dig("identifier") ||
        identifiers.find { |id| id["type"] == "ISBN_10" }&.dig("identifier")
    end

    def self.https_image(url)
      return nil if url&.include?("no_cover_thumb.gif")
      url&.gsub(/^http:\/\//, "https://")
    end

    def self.blank_result
      { items: [], total_count: 0 }
    end
  end
end
