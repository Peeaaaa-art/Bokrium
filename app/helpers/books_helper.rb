module BooksHelper
  def bookshelf_sample_notice
    return if user_signed_in? && !current_user.books.exists?
    return unless !user_signed_in? || @read_only

    content_tag :div, class: "alert-bokrium-info d-flex align-items-center text-center py-2 py-md-3" do
      content_tag :div, class: "container text-center text-sample" do
        concat content_tag(:i, nil, class: "bi bi-info-circle-fill fs-6 me-2")
        concat "こちらはサンプル表示です。自分の本棚をつくるためには、"
        concat link_to("ログイン", new_user_session_path)
        concat "・"
        concat link_to("アカウント登録", new_user_registration_path)
        concat "が必要です。"
      end
    end
  end

  def empty_bookshelf_notice
    return unless user_signed_in?
    return if current_user&.books&.exists?

    content_tag :div,
      class: "alert-bokrium-info d-flex align-items-center text-center py-2 py-md-3" do
      content_tag :div, class: "container text-center text-sample" do
        concat content_tag(:i, nil, class: "bi bi-info-circle-fill fs-6 me-2")
        concat "こちらはサンプル表示です。"
        concat link_to("最初の本を登録", search_books_path)
        concat "しましょう！"
      end
    end
  end

  def render_book_info_list(book, list_class: "list-unstyled fs-info text-secondary mb-0 lh-show")
    content_tag(:ul, class: list_class) do
      safe_join(
        book_info_items(book).map do |item|
          content_tag(:li) do
            icon_tag = bi_icon(item[:icon], css: "is-6 mb-1 me-1")
            value = sanitize(item[:value].to_s, tags: [], attributes: [])
            icon_tag + value
          end
        end
      )
    end
  end

  def book_info_items(book)
    [
      { icon: "person",            value: book.author },
      { icon: "building",          value: book.publisher },
      { icon: "upc",               value: book.isbn },
      { icon: "file-earmark-text", value: (book.page.present? ? "#{book.page} ページ" : nil) },
      { icon: "currency-yen",      value: (book.price.present? ? "#{book.price}円" : nil) }
    ].compact.select { |item| item[:value].present? }
  end

  def book_cover_credit(book_cover_url)
    return nil if book_cover_url.blank?

    source =
      case book_cover_url
      when /openbd|hanmoto/     then "OpenBD"
      when /rakuten/            then "Rakuten"
      when /books\.google/      then "Google"
      else nil
      end

    return nil if source.nil?
    "image from #{source}"
  end
end
