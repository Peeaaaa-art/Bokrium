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

  def books_index_path
    user_signed_in? ? books_path : guest_books_path
  end

  def books_index_active_class
    path_prefix = user_signed_in? ? "/books" : "/guest/books"
    request.path.starts_with?(path_prefix) ? "active" : ""
  end

  def book_link_path(book)
    user_signed_in? ? book_path(book) : guest_book_path(book)
  end

  def lazy_image_tag(source, options = {})
    options[:loading] ||= "lazy"
    image_tag(source, options)
  end
end
