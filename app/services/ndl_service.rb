class NdlService
  require "net/http"
  require "uri"
  require "rexml/document"

  ENDPOINT = "https://iss.ndl.go.jp/api/opensearch"

  def self.fetch(isbn)
    uri = URI.parse("#{ENDPOINT}?isbn=#{isbn}")
    response = Net::HTTP.get_response(uri)

    return nil unless response.is_a?(Net::HTTPSuccess)

    xml = REXML::Document.new(response.body)
    item = xml.elements["rss/channel/item"]
    return nil unless item

    {
      title: item.elements["title"]&.text,
      author: item.elements["dc:creator"]&.text,
      publisher: item.elements["dc:publisher"]&.text,
      isbn: isbn,
      price: nil,
      page: nil,
      book_cover: nil
    }
  rescue StandardError => e
    Rails.logger.error("[NdlService] #{e.message}")
    nil
  end
end
