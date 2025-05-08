module ApplicationHelper
  def nav_link_to(name = nil, path = nil, options = {}, &block)
    if block_given?
      path ||= name # 引数1個だけ渡されたとき
      name = capture(&block)
    end

    active = current_page?(path)
    classes = [ "nav-link", "footer-link" ]
    classes << "active fw-semibold" if active
    options[:class] = classes.join(" ")
    options[:"aria-current"] = "page" if active

    link_to name, path, options
  end
end
