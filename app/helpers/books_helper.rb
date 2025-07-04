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


  def display_book_cover(book, alt: nil,
                        s3_class: "", url_class: "", no_cover_class: "", no_cover_title: nil,
                        nocover_img: false, truncate_options: {}, **options)
    return unless book.present?
    alt ||= book.title.presence || "表紙画像"
    no_cover_title ||= book.title.truncate(40)

    if book.book_cover_s3.attached? && book.book_cover_s3.key.present?
      image_tag book.cloudfront_url, {
        alt: alt,
        loading: "lazy",
        class: "img-fluid #{s3_class}".strip,
        height: "auto"
      }.merge(options)

    elsif book.book_cover.present?
      image_tag book.book_cover,
                { alt: alt, loading: "lazy", class: "img-fluid #{url_class}",
                  style: "" }.merge(options)

    elsif nocover_img
      content_tag(:div, class: "cover-placeholder-wrapper #{no_cover_class}") do
        image_tag("no_cover.png", class: "img-fluid rounded-sm placeholder-cover") +
          content_tag(:div, truncate_for_device(book.title, **truncate_options),
                      class: "cover-title-overlay brake-word") +
          content_tag(:div, "Bokrium", class: "logo-overlay")
      end
    else
      content_tag(:div, { class: "no-cover #{no_cover_class}" }.merge(options)) do
        content_tag(:span, book.title&.truncate(40), class: "title #{ no_cover_title}")
      end
    end
  end


  def render_book_info_list(book, list_class: "list-unstyled fs-info text-secondary mb-0 lh-show")
    content_tag(:ul, class: list_class) do
      safe_join(
        book_info_items(book).map do |item|
          content_tag(:li) do
            icon_tag = content_tag(:i, "", class: "bi #{item[:icon]} me-1")
            value = sanitize(item[:value].to_s, tags: [], attributes: [])
            icon_tag + value
          end
        end
      )
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
