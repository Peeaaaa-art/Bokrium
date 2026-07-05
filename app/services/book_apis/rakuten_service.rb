module BookApis
  class RakutenService
    require "net/http"
    require "uri"
    require "json"

    ENDPOINT = "https://openapi.rakuten.co.jp/services/api/BooksBook/Search/20170404"
    MAX_HITS = 30

    class << self
      def fetch(isbn)
        return nil if isbn.blank?
        return nil unless credentials_available?

        response = request(isbn: isbn)
        return nil unless response.is_a?(Net::HTTPSuccess)

        body = JSON.parse(response.body)
        item = extract_items(body).first
        return nil unless item

        normalize_item(item)
      rescue StandardError => e
        Rails.logger.error("[RakutenService][ISBN] #{e.class}: #{e.message}")
        nil
      end

      def search_by_title_or_author(type:, query:, page: 1, hits: MAX_HITS)
        return blank_result if query.blank?
        return blank_result unless credentials_available?

        search_key = type.to_s == "author" ? :author : :title
        response = request(search_key => query, page: page, hits: hits)
        return blank_result unless response.is_a?(Net::HTTPSuccess)

        body = JSON.parse(response.body)
        {
          items: extract_items(body).map { |item| normalize_item(item) }.compact,
          total_count: extract_count(body)
        }
      rescue StandardError => e
        Rails.logger.error("[RakutenService][Search] #{e.class}: #{e.message}")
        blank_result
      end

      private

      def request(params)
        uri = URI.parse(ENDPOINT)
        uri.query = URI.encode_www_form(default_params.merge(params).compact)

        headers = {
          "Accept" => "application/json",
          "Origin" => HttpClient.request_origin,
          "Referer" => HttpClient.request_referer
        }
        headers["Authorization"] = "Bearer #{access_key}" if access_key.present?

        HttpClient.get(uri, headers: headers)
      end

      def default_params
        {
          applicationId: application_id,
          accessKey: access_key,
          formatVersion: 2
        }
      end

      def extract_items(body)
        items = body["items"] || body["Items"] || []

        Array(items).filter_map do |entry|
          next unless entry.is_a?(Hash)

          entry["item"] || entry["Item"] || entry
        end
      end

      def extract_count(body)
        body["count"].to_i
      end

      def normalize_item(item)
        return nil unless item.is_a?(Hash)

        image_url = item["largeImageUrl"] || item["mediumImageUrl"] || item["smallImageUrl"]
        image_url = nil if image_url&.match?(/noimage/i)

        {
          title: item["title"] || item["itemName"],
          author: item["author"] || item["authorName"],
          publisher: item["publisherName"] || item["makerName"],
          isbn: item["isbn"] || item["isbnJan"],
          price: item["itemPrice"] || item["price"],
          book_cover: image_url,
          page: nil,
          affiliate_url: item["affiliateUrl"] || item["itemUrl"]
        }
      end

      def blank_result
        { items: [], total_count: 0 }
      end

      def credentials_available?
        return true if application_id.present? && access_key.present?

        Rails.logger.warn("[RakutenService] Missing credentials: RAKUTEN_APPLICATION_ID and/or RAKUTEN_ACCESS_KEY")
        false
      end

      def application_id
        ENV["RAKUTEN_APPLICATION_ID"]
      end

      def access_key
        ENV["RAKUTEN_ACCESS_KEY"]
      end
    end
  end
end
