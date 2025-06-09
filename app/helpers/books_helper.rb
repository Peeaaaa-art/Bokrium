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

  def display_book_cover(book, resize_to: [ 200, 200 ], alt: nil,
                        s3_class: "", url_class: "", no_cover_class: "", no_cover_title: nil,
                        **options)
    alt ||= book.title.presence || "表紙画像"
    no_cover_title ||= book.title.truncate(40)

    scale_value = mobile? ? 1.3 : 1.4
    transform_style = "transform: scale(#{scale_value}); transform-origin: center;"

    if book.book_cover_s3.attached? && book.book_cover_s3.persisted? && book.book_cover_s3.variable?
      image_tag book.book_cover_s3.variant(resize_to_limit: resize_to),
                { alt: alt, loading: "lazy", class: "img-fluid #{s3_class}",
                  style: "#{transform_style}" }.merge(options)

    elsif book.book_cover.present?
      image_tag book.book_cover,
                { alt: alt, loading: "lazy", class: "img-fluid #{url_class}",
                  style: "#{transform_style}" }.merge(options)

    else
      content_tag(:div, { class: "no-cover #{no_cover_class}" }.merge(options)) do
        content_tag(:span, book.title&.truncate(40), class: "title #{ no_cover_title}")
      end
    end
  end

  def render_book_info_list(book, list_class: "list-unstyled fs-info text-secondary mb-0 lh-show")
    content_tag(:ul, class: list_class) do
      book_info_items(book).map do |item|
        content_tag(:li) do
          content_tag(:i, "", class: "bi #{item[:icon]} me-1") + item[:value]
        end
      end.join.html_safe
    end
  end

  def book_info_items(book)
    [
      { icon: "bi-person",            value: book.author },
      { icon: "bi-building",          value: book.publisher },
      { icon: "bi-upc",               value: book.isbn },
      { icon: "bi-file-earmark-text", value: (book.page.present? ? "#{book.page} ページ" : nil) },
      { icon: "bi-currency-yen",      value: (book.price.present? ? "#{book.price}円" : nil) }
    ].compact.select { |item| item[:value].present? }
  end
end
