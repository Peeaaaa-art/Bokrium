module BookApis
  class GoogleBooksService
    require "net/http"
    require "uri"
    require "json"

    ENDPOINT = "https://www.googleapis.com/books/v1/volumes"

    def self.fetch(isbn)
      return nil if isbn.blank?

      response = request(q: "isbn:#{isbn}")
      return nil unless response.is_a?(Net::HTTPSuccess)

      parse_response(JSON.parse(response.body), isbn)
    rescue StandardError => e
      Rails.logger.error("[GoogleBooksService][ISBN] #{e.message}")
      nil
    end

    def self.fetch_by_title_or_author(query, page = 1)
      return blank_result if query.blank?

      response = request(q: query, maxResults: 30, startIndex: (page - 1) * 30)
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

    def self.request(params)
      uri = URI.parse(ENDPOINT)
      uri.query = URI.encode_www_form(params.merge(api_key_param))

      req = Net::HTTP::Get.new(uri)
      req["Origin"] = request_origin
      req["Referer"] = request_referer

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 5

      response = http.request(req)

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.warn("[GoogleBooksService] Unexpected response: #{response.code} #{response.message}")
      end

      response
    end

    def self.api_key_param
      ENV["GOOGLE_BOOKS_API_KEY"].present? ? { key: ENV["GOOGLE_BOOKS_API_KEY"] } : {}
    end

    # Google CloudのAPIキーにHTTPリファラー制限をかけているため、
    # サーバーサイドのNet::HTTPが自動付与しないOrigin/Refererを明示する(RakutenServiceと同様)
    def self.request_origin
      raw = ENV["APP_HOST"].to_s.strip
      raw = "https://bokrium.com" if raw.blank?
      normalized = raw.match?(/\Ahttps?:\/\//) ? raw : "https://#{raw}"
      uri = URI.parse(normalized)
      origin = +"#{uri.scheme}://#{uri.host}"
      origin << ":#{uri.port}" if uri.port && uri.port != uri.default_port
      origin
    rescue URI::InvalidURIError
      "https://bokrium.com"
    end

    def self.request_referer
      "#{request_origin}/"
    end

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
