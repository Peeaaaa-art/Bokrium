class RakutenService
  def self.fetch(isbn)
    results = RakutenWebService::Books::Book.search(isbn: isbn)
    item = results.first
    return nil unless item

    {
      title: item.title,
      author: item.author,
      publisher: item.publisher_name,
      isbn: item.isbn,
      price: item.item_price,
      book_cover: item.large_image_url,
      page: nil
    }
  rescue RakutenWebService::Error => e
    Rails.logger.error("[RakutenService] #{e.message}")
    nil
  end
end
