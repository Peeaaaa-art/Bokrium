module ApplicationHelper
  def nav_link_to(name = nil, path = nil, options = {}, &block)
    if block_given?
      path ||= name
      name = capture(&block)
    end

    active = current_page?(path)
    classes = [ "nav-link", "footer-link" ]
    classes << "active fw-semibold" if active
    options[:class] = classes.join(" ")
    options[:"aria-current"] = "page" if active

    link_to name, path, options
  end

  def books_index_active_class
    path_prefix = user_signed_in? ? "/books" : "/guest/books"
    request.path.starts_with?(path_prefix) ? "active" : ""
  end

  def lazy_image_tag(source, options = {})
    return "" if source.blank?
    options[:loading] ||= "lazy"
    image_tag(source, options)
  end

  def lazy_section(frame_id, url)
    tag.div(
      data: {
        controller: "lazy-load",
        lazy_load_url_value: url,
        lazy_load_frame_value: frame_id
      }
    ) do
      tag.div(style: "height: 1px;")
    end +
      turbo_frame_tag(frame_id) do
        render "shared/loading_spinner"
      end
  end

  def truncate_for_device(text, mobile_limit: 10, desktop_limit: 13)
    limit = mobile? ? mobile_limit : desktop_limit
    truncate_mixed_width(text, limit: limit)
  end

  def cdn_path (filename)
    "https://lib.bokrium.com/images/#{filename}"
  end

  def book_added_message(book)
    sanitize(
      "本棚に#{link_to("『#{h(book.title.truncate(ApplicationController::TITLE_TRUNCATE_LIMIT))}』", book_path(book))}を追加しました。",
      tags: %w[a],
      attributes: %w[href]
    )
  end

  private

  def truncate_mixed_width(text, limit: 10)
    return "" if text.blank?

    display_width = 0
    result = ""

    text.each_char do |char|
      char_width = char.ascii_only? ? 0.6 : 1

      if display_width + char_width > limit
        result << "…"
        break
      end

      result << char
      display_width += char_width
    end

    result
  end
end
