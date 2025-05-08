module BookApis
  class OpenBdService
    require "net/http"
    require "uri"
    require "json"

    ENDPOINT = "https://api.openbd.jp/v1/get"

    def self.fetch(isbn)
      uri = URI.parse("#{ENDPOINT}?isbn=#{isbn}")
      response = Net::HTTP.get_response(uri)

      return nil unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)&.first
      return nil unless data

      {
        title:      data.dig("summary", "title"),
        author:     data.dig("summary", "author"),
        publisher:  data.dig("summary", "publisher"),
        isbn:       data.dig("summary", "isbn"),
        page:       data.dig("summary", "page")&.to_i,
        book_cover: data.dig("summary", "cover"),
        price: data.dig("onix", "ProductSupply", "SupplyDetail", "Price", 0, "PriceAmount")&.to_i
      }
    rescue StandardError => e
      Rails.logger.error("[OpenBdService] #{e.message}")
      nil
    end
  end
end
