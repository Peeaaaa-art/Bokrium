require "nokogiri"

module IconHelper
  def bi_icon(name, css: "", style: "", data: {})
    path = Rails.root.join("app/assets/icons/#{name}.svg")
    return "(missing icon)" unless File.exist?(path)

    svg = File.read(path)
    doc = Nokogiri::HTML::DocumentFragment.parse(svg)
    svg_tag = doc.at_css("svg")
    return "(invalid svg)" unless svg_tag

    svg_tag.remove_attribute("width")
    svg_tag.remove_attribute("height")

    # クラスとスタイルを反映
    svg_tag["class"] = [ svg_tag["class"], css ].reject(&:blank?).join(" ")
    svg_tag["style"] = style if style.present?

    # data属性を付加
    data.each do |key, value|
      svg_tag["data-#{key.to_s.dasherize}"] = value
    end

    doc.to_html.html_safe
  end
end
