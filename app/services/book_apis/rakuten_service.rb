module BookApis
  class RakutenService
    def self.fetch(isbn)
      results = RakutenWebService::Books::Book.search(isbn: isbn)
      item = results.first
      return nil unless item

      image_url = item.large_image_url
      image_url = nil if image_url&.match?(/noimage/i)

      {
        title:         item.title,
        author:        item.author,
        publisher:     item.publisher_name,
        isbn:          item.isbn,
        price:         item.item_price,
        book_cover:    image_url,
        page:          nil,
        affiliate_url: item.item_url
      }
    rescue RakutenWebService::Error => e
      Rails.logger.error("[RakutenService] #{e.message}")
      nil
    end
  end
end
