module MemosHelper
  PLACEHOLDER_TOKEN = "PLACEHOLDER_TOKEN_9fz3!ifhdas094hfgfygq@_$2x"
  SAFE_MEMO_LINK_REL = "noopener noreferrer nofollow ugc"
  SAFE_MEMO_LINK_TARGET = "_blank"
  SAFE_MEMO_LINK_CLASS = "memo-link"
  SAFE_MEMO_CONTENT_TAGS = %w[p br strong em a ul ol li blockquote h1 h2 h3 h4 h5 h6 code pre span hr s].freeze
  SAFE_MEMO_CONTENT_ATTRIBUTES = %w[href title target rel class].freeze
  MARKDOWN_LINK_PATTERN = /\[([^\]\n]{1,200})\]\((https?:\/\/[^\s<>"']{1,2048}?)\)/i
  SKIP_MARKDOWN_LINK_TAGS = %w[a code pre script style].freeze

  def memo_placeholder_html
    raw_html = <<~HTML
      <div data-placeholder="true" class="memo-placeholder mx-1 mx-md-5">
        <span style="display:none;">#{PLACEHOLDER_TOKEN}</span>
        <h3>メモを書き残しましょう</h3>
        <hr>
        <p>このエリアは <strong>マークダウン対応</strong> のリッチテキストエディタです。<br>
        あなたの読書体験や気づきを、自由に、そして丁寧に記録できます。</p>
        <p><em>※クリックするとモーダルで編集可能になります。</em></p>
      </div>
    HTML

    sanitize(raw_html, tags: %w[div span h3 hr p strong em br], attributes: %w[class style data-placeholder])
  end

  def how_to_use_tiptap_editor
    markdown_text = <<~MD
      ### 📖 使い方のヒント

      - `**強調**` → **強調されたテキスト**
      - `_斜体_` → *斜体*
      - `- 箇条書き` でリストが作れます
      - `> 引用文` で引用ブロックに
      - `` `コード` `` でインラインコードに

      > 記録することで、読書が「対話」になります。
    MD

    html = markdown_to_html(markdown_text)
    sanitize(html, tags: %w[p strong em ul ol li blockquote h1 h2 h3 code pre], attributes: [])
  end

  def markdown_to_html(text)
    renderer = Redcarpet::Render::HTML.new(filter_html: true, hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true)
    markdown.render(text)
  end

  def render_memo_content(content)
    html = convert_markdown_links_to_html(content.to_s)
    sanitized = sanitize(html, tags: SAFE_MEMO_CONTENT_TAGS, attributes: SAFE_MEMO_CONTENT_ATTRIBUTES)
    enforce_safe_memo_links(sanitized)
  end

  private

  def convert_markdown_links_to_html(html)
    fragment = Nokogiri::HTML::DocumentFragment.parse(html)
    text_nodes = []

    fragment.traverse do |node|
      text_nodes << node if node.text?
    end

    text_nodes.each do |node|
      next if node.ancestors.any? { |ancestor| SKIP_MARKDOWN_LINK_TAGS.include?(ancestor.name) }
      next unless node.text.match?(MARKDOWN_LINK_PATTERN)

      replace_markdown_links_in_node(node)
    end

    fragment.to_html
  end

  def replace_markdown_links_in_node(node)
    text = node.text
    document = node.document
    replacement = Nokogiri::HTML::DocumentFragment.parse("")
    cursor = 0
    replaced = false

    text.to_enum(:scan, MARKDOWN_LINK_PATTERN).each do
      match = Regexp.last_match
      safe_href = normalize_safe_memo_url(match[2])
      label = match[1].to_s.strip
      next if safe_href.blank? || label.blank?

      replacement.add_child(Nokogiri::XML::Text.new(text[cursor...match.begin(0)], document))
      replacement.add_child(memo_link_node(document, label, safe_href))
      cursor = match.end(0)
      replaced = true
    end

    return unless replaced

    replacement.add_child(Nokogiri::XML::Text.new(text[cursor..], document))
    node.replace(replacement)
  end

  def memo_link_node(document, label, href)
    link = Nokogiri::XML::Node.new("a", document)
    link["href"] = href
    link["target"] = SAFE_MEMO_LINK_TARGET
    link["rel"] = SAFE_MEMO_LINK_REL
    link["class"] = SAFE_MEMO_LINK_CLASS
    link.content = label
    link
  end

  def enforce_safe_memo_links(html)
    fragment = Nokogiri::HTML::DocumentFragment.parse(html.to_s)

    fragment.css("a").each do |link|
      safe_href = normalize_safe_memo_url(link["href"])

      unless safe_href
        link.replace(link.children)
        next
      end

      link["href"] = safe_href
      link["target"] = SAFE_MEMO_LINK_TARGET
      link["rel"] = SAFE_MEMO_LINK_REL
      link["class"] = [ link["class"], SAFE_MEMO_LINK_CLASS ].compact.join(" ")
    end

    fragment.to_html.html_safe
  end

  def normalize_safe_memo_url(value)
    uri = URI.parse(value.to_s.strip)
    return unless uri.is_a?(URI::HTTP) && uri.host.present?
    return unless %w[http https].include?(uri.scheme)

    uri.to_s
  rescue URI::InvalidURIError
    nil
  end
end
