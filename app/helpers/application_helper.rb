module ApplicationHelper
  def nav_link_to(name, path, options = {})
    active = current_page?(path)
    classes = [ "nav-link", "footer-link" ]
    classes << "active fw-semibold" if active
    options[:class] = classes.join(" ")
    options[:"aria-current"] = "page" if active
    link_to name, path, options
  end
end
