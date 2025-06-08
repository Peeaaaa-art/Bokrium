module ApplicationHelper
  include Pagy::Frontend

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

  def books_index_path
    if user_signed_in?
      current_user.books.exists? ? books_path : guest_books_path
    else
      guest_books_path
    end
  end

  def books_index_active_class
    path_prefix = user_signed_in? ? "/books" : "/guest/books"
    request.path.starts_with?(path_prefix) ? "active" : ""
  end

  def book_link_path(book)
    return guest_starter_book_path(book) if @starter_book

    if user_signed_in?
      current_user.books.exists? ? book_path(book) : guest_book_path(book)
    else
      guest_book_path(book)
    end
  end

  def lazy_image_tag(source, options = {})
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
end
