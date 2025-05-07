module BookApis
  class NdlService
    require "net/http"
    require "uri"
    require "nokogiri"

    ENDPOINT = "https://iss.ndl.go.jp/api/opensearch"
    THUMBNAIL_URL = "https://ndlsearch.ndl.go.jp/thumbnail"

    def self.fetch(isbn)
      return nil if isbn.blank?

      response = fetch_with_redirect("#{ENDPOINT}?isbn=#{isbn}")
      return nil unless response.is_a?(Net::HTTPSuccess)

      body = response.body.force_encoding("UTF-8")
      doc = Nokogiri::XML(body)
      doc.remove_namespaces!

      item = doc.at_xpath("//item")
      return nil unless item

      {
        title:     item.at_xpath("title")&.text,
        author:    item.at_xpath("creator")&.text,
        publisher: item.at_xpath("publisher")&.text,
        isbn: isbn,
        price:     nil,
        page:      nil,
        book_cover: fetch_thumbnail_url(isbn)
      }
    rescue StandardError => e
      Rails.logger.error("[NdlService] #{e.class}: #{e.message}")
      nil
    end

    private

    def self.fetch_with_redirect(uri_str, limit = 5)
      raise "Too many HTTP redirects" if limit == 0

      uri = URI.parse(uri_str)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      req = Net::HTTP::Get.new(uri)
      req["User-Agent"] = "Ruby/#{RUBY_VERSION}"

      res = http.request(req)

      case res
      when Net::HTTPSuccess
        res
      when Net::HTTPRedirection
        fetch_with_redirect(res["location"], limit - 1)
      else
        res.value # raise error
      end
    end

    def self.fetch_thumbnail_url(isbn)
      url = "#{THUMBNAIL_URL}/#{isbn}.jpg"
      response = Net::HTTP.get_response(URI.parse(url))
      response.is_a?(Net::HTTPSuccess) ? url : nil
    rescue StandardError => e
      Rails.logger.error("[NdlService][Thumbnail] #{e.class}: #{e.message}")
      nil
    end
  end
end
